IF OBJECT_ID('KPXCM_SPUDelvItemSave_MES') IS NOT NULL    
    DROP PROC KPXCM_SPUDelvItemSave_MES
GO 

-- v2015.09.23 KPXCM MES ��

/************************************************************      
 ��  �� - ���Ű��� �� ����      
 �ۼ��� - 2008�� 8�� 20��       
 �ۼ��� - �뿵��      
 ������ - 2009�� 9�� 2��      
 ������ - ����(���˻�ǰ �ڵ��԰� �߰�)      
 ������ - 2010�� 10�� 21��    
 ������ - �̿���( MakerSeq �߰�)    
 ������ - 2011. 12. 30 hkim (�������� ���� ����, ������Ʈ �ǵ��� ����)  
        - 2013.  7. 10 õ��� (Memo1~8 �÷� �߰�)  
 ************************************************************/      
     
 CREATE PROC dbo.KPXCM_SPUDelvItemSave_MES
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT = 0,        
     @ServiceSeq     INT = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
     @CompanySeq     INT = 1,        
     @LanguageSeq    INT = 1,        
     @UserSeq        INT = 0,        
     @PgmSeq         INT = 0        
       
 AS          
     DECLARE @VatAccSeq    INT,      
             @QCAutoIn     NCHAR(1),      
             @DelvInSeq    INT,      
             @DelvInSerl   INT,      
             @DelvInNo     NCHAR(12),      
             @DelvInDate   NCHAR(8),      
             @BuyingAccSeq INT      
       
     -- ���� ����Ÿ ��� ����      
     CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)        
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'           
     IF @@ERROR <> 0 RETURN          
       
     -- PgmSeq �۾� 2014�� 07�� 20�� �ϰ� �۾��մϴ�. (���� ����ȭ �Ǹ� ��������)   
     IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvItem' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
     BEGIN  
            ALTER TABLE _TPUDelvItem ADD PgmSeq INT NULL  
     END   
   
     IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvItemLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
     BEGIN  
            ALTER TABLE _TPUDelvItemLog ADD PgmSeq INT NULL  
     END    
       
       
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)      
     EXEC _SCOMLog  @CompanySeq   ,      
                    @UserSeq      ,      
                    '_TPUDelvItem', -- �����̺��      
                    '#TPUDelvItem', -- �������̺��      
                    'DelvSeq,DelvSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.       
                    'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,      
                     Price,Qty,CurAmt,CurVAT,DomPrice,      
                     DomAmt,DomVAT,IsVAT,StdUnitSeq,StdUnitQty,      
                     SMQcType,QcEmpSeq,QcDate,QcQty,QcCurAmt,      
                     WHSeq,LOTNo,FromSerial,ToSerial,SalesCustSeq,      
                     DelvCustSeq,PJTSeq,WBSSeq,UMDelayType,Remark,      
                     IsReturn,LastUserSeq,LastDateTime,MakerSeq,SourceSeq,SourceSerl,IsFiction,FicRateNum,  
                     FicRateDen,EvidSeq,Memo1,Memo2,Memo3,Memo4,Memo5,Memo6,Memo7,Memo8,SMPriceType,PgmSeq'      
                     ,'',@PgmSeq  
       
     -- DELETE          
     IF EXISTS (SELECT TOP 1 1 FROM #TPUDelvItem WHERE WorkingTag = 'D' AND Status = 0)        
     BEGIN        
       
             DELETE _TPUDelvItem      
               FROM _TPUDelvItem A WITH(NOLOCK)
                   JOIN #TPUDelvItem B WITH(NOLOCK) ON A.DelvSeq = B.DelvSeq       
                                                   AND A.DelvSerl = B.DelvSerl      
              WHERE B.WorkingTag = 'D' AND B.Status = 0          
                AND A.CompanySeq  = @CompanySeq      
             IF @@ERROR <> 0  RETURN      
       
     END        
       
     -- UPDATE          
     IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag = 'U' AND Status = 0)        
     BEGIN      
       
             UPDATE _TPUDelvItem      
                SET        
                     ItemSeq      = B.ItemSeq      ,      
                     UnitSeq      = B.UnitSeq      ,      
                     Price        = ISNULL(B.Price        , 0),      
                     DomPrice     = ISNULL(B.DomPrice     , 0),      
   Qty          = ISNULL(B.Qty          , 0),      
                     CurAmt       = ISNULL(B.CurAmt        , 0),      
                     DomAmt       = ISNULL(B.DomAmt       , 0),      
                       CurVAT       = ISNULL(B.CurVAT       , 0),      
                     DomVAT       = ISNULL(B.DomVAT       , 0),      
                     IsVAT        = B.IsVAT        ,      
                     StdUnitSeq   = B.StdUnitSeq   ,      
                     StdUnitQty   = B.StdUnitQty   ,      
                     --SMQcType     = B.SMQcType     ,    -- 2014.03.04 ����� �˻� ������ �̹� ���Ű˻��Ƿڿ��� ó�����ֹǷ�  
                                                          -- �ι� ó�� �� �ʿ� ��� �ּ�ó��  
                     QcEmpSeq     = B.QcEmpSeq     ,      
                     QcDate       = B.QcDate       ,      
                     QcQty        = B.QcQty        ,      
                     QcCurAmt     = B.QcCurAmt     ,      
                     WHSeq        = B.WHSeq        ,      
                     LOTNo        = B.LOTNo        ,      
                     FromSerial   = B.FromSerial   ,      
                     ToSerial     = B.ToSerial     ,      
                     SalesCustSeq = B.SalesCustSeq ,      
                     DelvCustSeq  = B.DelvCustSeq  ,      
                     PJTSeq       = B.PJTSeq       ,      
                     WBSSeq       = B.WBSSeq       ,      
                     UMDelayType  = B.UMDelayType  ,      
                     Remark       = B.Remark       ,      
                     IsReturn     = B.IsReturn     ,      
                     LastUserSeq  = @UserSeq,      
                     LastDateTime = GETDATE(),    
                     MakerSeq     = B.MakerSeq     ,         -- MakerSeq  �߰�    
                     IsFiction    = B.IsFiction    ,         --2011. 12. 30 hkim �߰�  
                     FicRateNum   = B.FicRateNum   ,         --2011. 12. 30 hkim �߰�  
                     FicRateDen   = B.FicRateDen   ,         --2011. 12. 30 hkim �߰�  
                     EvidSeq      = B.EvidSeq      ,         --2011. 12. 30 hkim �߰�  
                     Memo1        = B.Memo1,  
                     Memo2        = B.Memo2,  
                     Memo3        = B.Memo3,  
                     Memo4        = B.Memo4,  
                     Memo5        = B.Memo5,  
                     Memo6        = B.Memo6,  
                     Memo7        = B.Memo7,  
                     Memo8        = B.Memo8,  
                     SMPriceType  = B.SMPriceType,  
                     PgmSeq       = @PgmSeq  
               FROM _TPUDelvItem AS A WITH(NOLOCK) 
                    JOIN #TPUDelvItem AS B WITH(NOLOCK) ON A.DelvSeq = B.DelvSeq       
                                                       AND A.DelvSerl = B.DelvSerl      
              WHERE B.WorkingTag  = 'U'       
                AND B.Status      = 0          
                AND A.CompanySeq  = @CompanySeq        
             IF @@ERROR <> 0  RETURN      
     END      
       
       
     -- INSERT      
     IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag = 'A' AND Status = 0)        
     BEGIN        
         INSERT INTO _TPUDelvItem(CompanySeq   ,DelvSeq      ,DelvSerl     ,ItemSeq      ,UnitSeq      ,      
                                 Price        ,Qty          ,CurAmt       ,DomAmt       ,StdUnitSeq    ,      
                                 StdUnitQty   ,SMQcType     ,QcEmpSeq     ,QcDate       ,QcQty        ,      
                                 QcCurAmt     ,WHSeq        ,LOTNo        ,FromSerial   ,ToSerial     ,      
                                 SalesCustSeq ,DelvCustSeq  ,PJTSeq       ,WBSSeq       ,UMDelayType  ,      
                                 DomPrice     ,CurVAT       ,DomVAT       ,IsVAT        ,      
                                 Remark       ,IsReturn     ,LastUserSeq  ,LastDateTime, MakerSeq     ,       -- MakerSeq  �߰�    
                                 IsFiction    ,FicRateNum   ,FicRateDen   ,EvidSeq, SupplyAmt, SupplyVAT,  
                                 Memo1        ,Memo2        ,Memo3        ,Memo4        ,Memo5        ,  
                        Memo6        ,Memo7        ,Memo8        ,SMPriceType  ,PgmSeq)  
         SELECT  @CompanySeq     ,DelvSeq      ,DelvSerl        ,ItemSeq         ,UnitSeq      ,      
                   ISNULL(Price,0)   ,ISNULL(Qty,0)   ,ISNULL(CurAmt,0) ,ISNULL(DomAmt,0) ,StdUnitSeq   ,      
                 StdUnitQty        ,SMQcType        ,QcEmpSeq         ,QcDate           ,QcQty        ,      
                 QcCurAmt          ,WHSeq           ,LOTNo            ,FromSerial       ,ToSerial     ,      
                 SalesCustSeq      ,DelvCustSeq     ,PJTSeq           , WBSSeq          ,UMDelayType  ,      
                 ISNULL(DomPrice,0),ISNULL(CurVAT,0),ISNULL(DomVAT,0) ,IsVAT            ,      
                 Remark            ,IsReturn        ,@UserSeq         ,GETDATE(),    ISNULL(MakerSeq,0),   -- MakerSeq  �߰�    
                 ISNULL(IsFiction, '0')         ,FicRateNum      ,FicRateDen       ,EvidSeq, ISNULL(DomAmt,0), 0, --ISNULL(DomVAT,0)  -- ���ް��� �÷��� ��ȭ �ݾ�, �ΰ��� ������ �߰� 2012. 5. 22 hkim  
                 Memo1        ,Memo2        ,Memo3        ,Memo4        ,Memo5        ,  
                 Memo6        ,Memo7        ,Memo8        ,SMPriceType  ,@PgmSeq  
           FROM #TPUDelvItem AS A WITH(NOLOCK)        
          WHERE A.WorkingTag = 'A' AND A.Status = 0          
         IF @@ERROR <> 0 RETURN      
     END         
       
           
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TPUDelvItem )  
      
    RETURN @Status  
    