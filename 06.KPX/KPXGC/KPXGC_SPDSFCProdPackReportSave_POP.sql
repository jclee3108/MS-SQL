
IF OBJECT_ID('KPXGC_SPDSFCProdPackReportSave_POP') IS NOT NULL 
    DROP PROC KPXGC_SPDSFCProdPackReportSave_POP
GO 
      
-- v2015.08. 26
      
-- POP ���� ��������Է�(Lot��ü, �̵�ó��) by����õ     
      
/*********************************************************************************************************  
  
-- Relation Table�� DataKind   
  
1 - ������� ���Թ� Lot ��ü(����)
2 - ������� ������� ������ũ�� �̵� (����)
3 - ������� �Ϲ� Lot�� ���Թ� Lot�� ��ü (����)  
4 - ������� Lot��ü (��ũ)   
5 - ������� ������� ������ũ�� �̵�(��ũ)
6 - ��� ��Ÿ��� 

*********************************************************************************************************/  
CREATE PROC KPXGC_SPDSFCProdPackReportSave_POP       
    
    @CompanySeq INT 
    
AS       
    
    CREATE TABLE #BaseData       
    (      
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50) 
    )      
    
    -- ���� ������ 
    INSERT INTO #BaseData 
    (        
        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
        UMProgType 
    )        
    SELECT TOP 10 
           A.Seq, A.WorkingTag, C.FactUnit, A.IsPacking, A.WorkOrderSeq, 
           A.WorkOrderSerl, ISNULL(E.SourceSeq,0), ISNULL(E.SourceSerl,0), A.GoodItemSeq, ISNULL(A.ProdQty,0) - (ISNULL(A.HambaQty,0) + ISNULL(A.DrainQty,0)) - ISNULL(D.UseQty,0), 
           A.RealLotNo, ISNULL(A.HambaQty,0) + ISNULL(A.DrainQty,0), A.WorkEndDate, ISNULL(A.ProdQty,0), ISNULL(D.UseQty,0), 
           ISNULL(E.OutWHSeq,0), ISNULL(E.InWHSeq,0), E.SubItemSeq, A.SubQty, ISNULL(E.SubOutWHSeq,0), 
           F.UMProgType 
      FROM KPX_TPDSFCWorkReport_POP AS A       
      OUTER APPLY( SELECT Z.FactUnit    
                     FROM KPX_TPDSFCWorkOrder_POP AS Z     
                    WHERE Z.CompanySeq = @CompanySeq     
                      AND Z.WorkOrderSeq = A.WorkOrderSeq     
                      AND Z.WorkorderSerl = A.WorkOrderSerl     
                      AND Z.IsPacking = A.IsPacking     
                      AND Z.Serl = (     
                                    SELECT MAX(Serl) AS Serl     
                                      FROM KPX_TPDSFCWorkOrder_POP AS Y    
                                     WHERE Y.companyseq = @CompanySeq      
                                       AND Y.WorkOrderSeq = Z.WorkOrderSeq    
                                       AND Y.WorkOrderSerl = Z.WorkOrderSerl    
                                   )    
                 ) AS C   
      OUTER APPLY (  
                    SELECT SUM(UseQty) AS UseQty 
                      FROM KPX_TPDPackingHanbaInPut_POP AS Z   
                     WHERE Z.CompanySeq = @CompanySeq   
                       AND Z.WorkOrderSeq = A.WorkOrderSeq   
                       AND Z.WorkOrderSerl = A.WorkOrderSerl   
                 ) AS D 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem   AS E ON ( E.CompanySeq = @CompanySeq AND E.PackOrderSeq = A.WorkOrderSeq AND E.PackOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder       AS F ON ( F.CompanySeq = @CompanySeq AND F.PackOrderSeq = E.PackOrderSeq ) 
     --WHERE A.ProcYn = '0'         
     --  AND A.IsPacking = '1'         
     --  AND ISNULL(C.FactUnit,0) <> 0       
     --  AND ISNULL(A.WorkEndDate,'') <> ''   
    where A.seq in (  12296 , 4150, 13453, 13454 ) 
     ORDER BY A.Seq     
    
    
    
    -- ��õ���� - ���� 
    CREATE TABLE #TypeOne
    (
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50) 
    )
    INSERT INTO #TypeOne 
    (        
        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
        UMProgType 
    )    
    SELECT Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
           WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
           RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
           OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
           UMProgType 
      FROM #BaseData 
     WHERE UMProgType = 1010345001 
    
    -- ��õ���� - ��ũ 
    CREATE TABLE #TypeTwo
    (
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50) 
    )
    INSERT INTO #TypeTwo 
    (        
        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
        UMProgType 
    )    
    SELECT Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
           WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
           RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
           OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
           UMProgType 
      FROM #BaseData 
     WHERE UMProgType = 1010345002 
    
    
    
    
    --select * from #TypeOne 
    
    
    
    IF EXISTS (SELECT 1 FROM #TypeOne) 
    BEGIN 
        /*******************************************************************************************************
        -- ���� 
        *******************************************************************************************************/
        ---------------------------------------------------------------------------------
        -- ���Թ� Lot ��ü (�Թ� Lot -> ����Lot) - ������ũ 
        ---------------------------------------------------------------------------------
        DECLARE @Count      INT, 
                @Seq        INT, 
                @BizUnit    INT, 
                @Date       NCHAR(8), 
                @MaxNo      NVARCHAR(50), 
                @Cnt        INT 
        
        SELECT @Count = (SELECT COUNT(1) FROM #TypeOne) 
            
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- Ű�������ڵ�κ� ����                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe �� ������ Ű�� UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeOne AS A 
         WHERE WorkingTag = 'A'       
        
        -- ����, ����  �� ��� ���� ���� ���̺� InOutSeq,Serl �� ������Ʈ       
        UPDATE A       
           SET InOutSeq = B.InOutSeq      
          FROM #TypeOne AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 1 
                                                      AND B.InOutType = 310 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )      
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag = 'A')       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeOne AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeOne              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeOne)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
        
        --BEGIN TRAN 
        
        -- ����, ���� �� ���� 
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- �ű�, ���� �� �Է� 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.OutWHSeq, 
               0, '', '', 0, 0, 
               '', 0, '������� ���Թ� Lot ��ü', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 310, A.InOutSeq, 1, A.GoodItemSeq, 
               '������� ���Թ� Lot ��ü', NULL, NULL, A.OutWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.BeforHambaQty, A.BeforHambaQty, 0, 0, 
               0, 8023042, 0, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, 'hambaLot', NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeOne AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 1, 310, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag = 'A' 
        ---------------------------------------------------------------------------------
        -- ���Թ� Lot ��ü (�Թ� Lot -> ����Lot) - ������ũ, END 
        ---------------------------------------------------------------------------------
        
        ---------------------------------------------------------------------------------
        -- ������� �̵�ó�� (������ũ -> �Ϲ�â��) 
        ---------------------------------------------------------------------------------
        SELECT @Count = (SELECT COUNT(1) FROM #TypeOne) 
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- Ű�������ڵ�κ� ����                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe �� ������ Ű�� UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeOne AS A 
         WHERE WorkingTag = 'A'       
        
        --select * From _TDASMinor where majorseq = 8042 and companyseq = 1 
        -- ����, ����  �� ��� ���� ���� ���̺� InOutSeq,Serl �� ������Ʈ       
        UPDATE A       
           SET InOutSeq = B.InOutSeq      
          FROM #TypeOne AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 2 
                                                      AND B.InOutType = 80 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )        
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag = 'A')       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeOne AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeOne              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeOne)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END      
        
        -- ����, ���� �� ���� 
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- �ű�, ���� �� �Է� 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 80, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.InWHSeq, 
               0, '0', '1', 0, 0, 
               '', 0, '������� ������� ������ũ�� �̵�', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 80, A.InOutSeq, 1, A.GoodItemSeq, 
               '������� ������� ������ũ�� �̵�', NULL, NULL, A.InWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.ProdQty, A.ProdQty, 0, 0, 
               0, 8023008, 8012001, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, NULL, NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeOne AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 2, 80, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag  = 'A' 
        ---------------------------------------------------------------------------------
        -- ������� �̵�ó�� (������ũ -> �Ϲ�â��), END  
        ---------------------------------------------------------------------------------
        
        ---------------------------------------------------------------------------------
        -- �Թ� ���� Lot��ü (���� Lot -> �Թ� Lot) - ������ũ 
        ---------------------------------------------------------------------------------
        SELECT @Count = (SELECT COUNT(1) FROM #TypeOne) 
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- Ű�������ڵ�κ� ����                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe �� ������ Ű�� UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeOne AS A 
         WHERE WorkingTag = 'A'       
        
        -- ����, ����  �� ��� ���� ���� ���̺� InOutSeq,Serl �� ������Ʈ       
        UPDATE A       
           SET InOutSeq = B.InOutSeq      
          FROM #TypeOne AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 3 
                                                      AND B.InOutType = 310 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )      
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag = 'A')       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeOne AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeOne              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeOne)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
        
        
        -- ����, ���� �� ���� 
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- �ű�, ���� �� �Է� 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.OutWHSeq, 
               0, '', '', 0, 0, 
               '', 0, '������� �Ϲ� Lot�� ���Թ� Lot�� ��ü', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 310, A.InOutSeq, 1, A.GoodItemSeq, 
               '������� �Ϲ� Lot�� ���Թ� Lot�� ��ü', NULL, NULL, A.OutWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.HambaDrainQty, A.HambaDrainQty, 0, 0, 
               0, 8023042, 0, 'hambaLot', '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, A.RealLotNo, NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeOne AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 3, 310, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag = 'A' 
        ---------------------------------------------------------------------------------
        -- �Թ� ���� Lot��ü (���� Lot -> �Թ� Lot) - ������ũ, END 
        --------------------------------------------------------------------------------- 
        
        --IF @@ERROR <> 0 
        --BEGIN
        --    ROLLBACK 
        --END 
        
        
    END 
    
    
    CREATE TABLE #TypeTwo_Result
    (
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50), 
        LotNo           NVARCHAR(50) 
    )
    
    
    IF EXISTS (SELECT 1 FROM #TypeTwo)
    BEGIN
        /*******************************************************************************************************
        -- ��ũ  
        *******************************************************************************************************/
        DECLARE @DateFr     NCHAR(8), 
                @WHSeq      INT, 
                @FactUnit   INT, 
                @IFSeq      INT, 
                @LotNo      NVARCHAR(50)     
                 
        SELECT @DateFr = CONVERT(NCHAR(8),GETDATE(),112)     
        
        CREATE TABLE #GetInOutLot            
        (              
            LotNo         NVARCHAR(30),            
            ItemSeq       INT        
        )      
        CREATE TABLE #GetInOutLotStock              
        (              
            WHSeq           INT,              
            FunctionWHSeq   INT,              
            LotNo           NVARCHAR(30),            
            ItemSeq         INT,              
            UnitSeq         INT,              
            PrevQty         DECIMAL(19,5),              
            InQty           DECIMAL(19,5),              
            OutQty          DECIMAL(19,5),              
            StockQty        DECIMAL(19,5),              
            STDPrevQty      DECIMAL(19,5),              
            STDInQty        DECIMAL(19,5),              
            STDOutQty       DECIMAL(19,5),              
            STDStockQty     DECIMAL(19,5)              
        )  
        
        CREATE TABLE #GetInOutLotStock_Sub      
        (         
            IDX_NO          INT IDENTITY,       
            RegDate         NCHAR(8),       
            WHSeq           INT,              
            FunctionWHSeq   INT,              
            LotNo           NVARCHAR(30),            
            ItemSeq         INT,              
            UnitSeq         INT,              
            PrevQty         DECIMAL(19,5),              
            InQty           DECIMAL(19,5),              
            OutQty          DECIMAL(19,5),              
            StockQty        DECIMAL(19,5),              
            STDPrevQty      DECIMAL(19,5),              
            STDInQty        DECIMAL(19,5),              
            STDOutQty       DECIMAL(19,5),              
            STDStockQty     DECIMAL(19,5), 
            Seq             INT 
        )            
        
        SELECT @Cnt  = 1 
        WHILE ( 1 = 1 ) 
        BEGIN
            
            TRUNCATE TABLE #GetInOutLot      
            INSERT INTO #GetInOutLot ( LotNo, ItemSeq )         
            SELECT DISTINCT B.LotNo, A.GoodItemSeq        
              FROM #TypeTwo     AS A         
              JOIN _TLGLotStock AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq )      
             WHERE A.IDX_NO = @Cnt 
            


            SELECT @BizUnit = C.BizUnit, 
                   @WHSeq = 2, 
                   @FactUnit = A.FactUnit, 
                   @IFSeq = A.Seq 
              FROM #TypeTwo AS A 
              LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl ) 
              LEFT OUTER JOIN _TDAWH AS C ON ( C.CompanySeq = @CompanySeq AND C.WHSeq = 2 ) 
             WHERE A.IDX_NO = @Cnt 
            
            
            TRUNCATE TABLE #GetInOutLotStock 
            -- â����� ��������              
            EXEC _SLGGetInOutLotStock @CompanySeq   = @CompanySeq,   -- �����ڵ�              
                                      @BizUnit      = @BizUnit,      -- ����ι�              
                                      @FactUnit     = @FactUnit,     -- ��������              
                                      @DateFr       = @DateFr,       -- ��ȸ�ⰣFr              
                                      @DateTo       = @DateFr,       -- ��ȸ�ⰣTo              
                                      @WHSeq        = @WHSeq,        -- â������              
                                      @SMWHKind     = 0,     -- â���к� ��ȸ              
                                      @CustSeq      = 0,      -- ��Ź�ŷ�ó              
                                      @IsTrustCust  = '0',  -- ��Ź����              
                                      @IsSubDisplay = '0', -- ���â�� ��ȸ              
                                      @IsUnitQry    = '0',    -- ������ ��ȸ              
                                      @QryType      = 'S'       -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������  
            
            TRUNCATE TABLE #GetInOutLotStock_Sub 
            
            INSERT INTO #GetInOutLotStock_Sub       
            SELECT B.RegDate, A.*, @IFSeq 
              FROM #GetInOutLotStock AS A         
              LEFT OUTER JOIN _TLGLotMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.LotNo = A.LotNo AND B.ItemSeq = A.ItemSeq )         
             WHERE A.STDStockQty > 0       
             ORDER BY B.RegDate DESC      
            
            
            IF (SELECT ProdQty FROM #TypeTwo WHERE Seq = @IFSeq) > (SELECT ISNULL(SUM(STDStockQty),0) FROM  #GetInOutLotStock_Sub)
            BEGIN
                
                UPDATE A 
                   SET ProcYn = '2', 
                       ErrorMessage = '��� �����Ͽ� ó�� �� �� �����ϴ�.(��ũ)' 
                  FROM KPX_TPDSFCWorkReport_POP AS A 
                 WHERE Seq = @IFSeq 
                
            END 
            ELSE 
            BEGIN
                DECLARE @StockCnt   INT, 
                        @ProdQty    DECIMAL(19,5), 
                        @StockQty   DECIMAL(19,5) 
                
                SELECT @ProdQty = ProdQty 
                  FROM #TypeTwo 
                 WHERE IDX_NO = @Cnt 
                
                SELECT @StockCnt = 1 
                --select @OriQty 
                --SELECT * from #TypeTwo
                --return 
                WHILE ( 1 = 1 ) 
                BEGIN
                    
                    SELECT @StockQty = STDStockQty, 
                           @LotNo = LotNo  
                      FROM #GetInOutLotStock_Sub 
                     WHERE IDX_NO = @StockCnt 
                    
                    --SELECT @StockQty = 6000
                    --select @StockQty , @ProdQty
                    
                    INSERT INTO #TypeTwo_Result 
                    (        
                        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
                        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
                        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
                        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
                        UMProgType, LotNo 
                    )    
                    SELECT A.Seq, A.WorkingTag, A.FactUnit, A.IsPacking, A.WorkOrderSeq, 
                           A.WorkOrderSerl, A.SourceSeq, A.SourceSerl, A.GoodItemSeq, CASE WHEN @StockQty >= @ProdQty THEN @ProdQty ELSE @StockQty END, 
                           A.RealLotNo, A.HambaDrainQty, A.WorkEndDate, CASE WHEN @StockQty >= @ProdQty THEN @ProdQty ELSE @StockQty END, A.BeforHambaQty, 
                           A.OutWHSeq, A.InWHSeq, A.SubItemSeq, A.SubQty, A.SubOutWHSeq, 
                           A.UMProgType, @LotNo 
                      FROM #TypeTwo AS A 
                     WHERE Seq = @IFSeq 
                    
                    IF @StockCnt >= (SELECT MAX(IDX_NO) FROM #GetInOutLotStock_Sub)
                       OR @StockQty >= @ProdQty 
                    BEGIN 
                        BREAK
                    END 
                    ELSE
                    BEGIN
                        SELECT @StockCnt = @StockCnt + 1 
                        SELECT @ProdQty = @ProdQty - @StockQty 
                    END 
                
                
                END 
            
            END 
            
            IF @Cnt >= (SELECT MAX(IDX_NO) FROM #TypeTwo)
            BEGIN 
                BREAK 
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        
        END 
    
        --select *From #TypeTwo_Result 
        --return 
        SELECT @Count = (SELECT COUNT(1) FROM #TypeTwo_Result)
        ---------------------------------------------------------------------------------
        -- ������ũ Lot ��ü - ���Լ��� (��ũ) 
        ---------------------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM #TypeTwo_Result WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- Ű�������ڵ�κ� ����                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe �� ������ Ű�� UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeTwo_Result AS A 
         WHERE WorkingTag = 'A'       
        
        -- ����, ����  �� ��� ���� ���� ���̺� InOutSeq,Serl �� ������Ʈ       
        UPDATE A       
           SET InOutSeq = B.InOutSeq      
          FROM #TypeTwo_Result AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 4 
                                                      AND B.InOutType = 310 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )      
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeTwo_Result WHERE WorkingTag = 'A')       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeTwo_Result AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeTwo_Result              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeTwo_Result)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
        
        
        -- ����, ���� �� ���� 
        DELETE B 
          FROM #TypeTwo_Result AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeTwo_Result AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- �ű�, ���� �� �Է� 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.OutWHSeq, 
               0, '', '', 0, 0, 
               '', 0, '������� Lot��ü (��ũ)', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeTwo_Result AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 310, A.InOutSeq, 1, A.GoodItemSeq, 
               '������� Lot��ü (��ũ)', NULL, NULL, A.OutWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.HambaDrainQty, A.HambaDrainQty, 0, 0, 
               0, 8023042, 0, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, A.LotNo, NULL, 
               NULL, NULL, NULL, 1021351
          FROM #TypeTwo_Result AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 4, 310, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeTwo_Result AS A 
         WHERE A.WorkingTag = 'A' 
--select * from #TypeTwo

        SELECT @Count = (SELECT COUNT(1) FROM #TypeTwo)
        ---------------------------------------------------------------------------------
        -- ������� �̵�ó�� (������ũ -> �Ϲ�â��) (��ũ)
        ---------------------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM #TypeTwo WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- Ű�������ڵ�κ� ����                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe �� ������ Ű�� UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeTwo AS A 
         WHERE WorkingTag = 'A'       
        
        --select * From _TDASMinor where majorseq = 8042 and companyseq = 1 
        -- ����, ����  �� ��� ���� ���� ���̺� InOutSeq,Serl �� ������Ʈ       
        UPDATE A       
           SET InOutSeq = B.InOutSeq      
          FROM #TypeTwo AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 5 
                                                      AND B.InOutType = 80 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )        
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeTwo WHERE WorkingTag = 'A')       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeTwo AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeTwo              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeTwo)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END      
        
        -- ����, ���� �� ���� 
        DELETE B 
          FROM #TypeTwo AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeTwo AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- �ű�, ���� �� �Է� 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 80, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.InWHSeq, 
               0, '0', '1', 0, 0, 
               '', 0, '������� ������� ������ũ�� �̵�(��ũ)', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeTwo AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 80, A.InOutSeq, 1, A.GoodItemSeq, 
               '������� ������� ������ũ�� �̵�(��ũ)', NULL, NULL, A.InWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.ProdQty, A.ProdQty, 0, 0, 
               0, 8023008, 8012001, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, NULL, NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeTwo AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 5, 80, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeTwo AS A 
         WHERE A.WorkingTag = 'A' 
        ---------------------------------------------------------------------------------
        -- ������� �̵�ó�� (������ũ -> �Ϲ�â��), END  
        ---------------------------------------------------------------------------------
    END 
    
    --select * from #BaseData
    
    SELECT @Count = (SELECT COUNT(1) FROM #BaseData)
    ---------------------------------------------------------------------------------
    -- ��� ��Ÿ��� 
    ---------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM #BaseData WHERE WorkingTag = 'A')       
    BEGIN       
        DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
        -- Ű�������ڵ�κ� ����                
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
    END          
    
             
    -- Temp Talbe �� ������ Ű�� UPDATE       
    UPDATE A               
       SET InOutSeq = @Seq + IDX_NO         
      FROM #BaseData AS A 
     WHERE WorkingTag = 'A'       
    
    --select * From _TDASMinor where majorseq = 8042 and companyseq = 1 
    -- ����, ����  �� ��� ���� ���� ���̺� InOutSeq,Serl �� ������Ʈ       
    UPDATE A       
       SET InOutSeq = B.InOutSeq      
      FROM #BaseData AS A       
      JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                  AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                  AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                  AND B.DataKind = 6  
                                                  AND B.InOutType = 30 
                                                  --AND B.InOutSeq = A.InOutSeq 
                                                  --AND B.InOutSerl = 1 
                                                    )        
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
    
              
    SELECT @Cnt = 1         
    
    IF EXISTS (SELECT 1 FROM #BaseData WHERE WorkingTag = 'A')       
    BEGIN       
        WHILE ( 1 = 1 )          
        BEGIN 
            
            SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                   @Date = WorkEndDate
              FROM #BaseData AS A 
             WHERE IDX_NO = @Cnt 
            
            exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                    
            UPDATE #BaseData              
               SET InOutNo = @MaxNo         
              WHERE IDX_NO = @Cnt        
                    
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #BaseData)         
            BEGIN         
                BREAK         
            END         
            ELSE         
            BEGIN        
                SELECT @Cnt = @Cnt + 1         
            END         
        END         
    END      
    
    -- ����, ���� �� ���� 
    DELETE B 
      FROM #BaseData AS A 
      JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 30 ) 
     WHERE A.WorkingTag IN ( 'D', 'U' ) 
    
    DELETE B 
      FROM #BaseData AS A 
      JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 30 ) 
     WHERE A.WorkingTag IN ( 'D', 'U' ) 
    
    
    -- �ű�, ���� �� �Է� 
    INSERT INTO _TLGInOutDaily 
    (
        CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
        FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
        WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
        DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
        CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
        LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
    )
    
    SELECT @CompanySeq, 30, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
           0, 0, 0, 0, A.WorkEndDate, 
           0, 0, 0, A.SubOutWHSeq, 0, 
           0, '', '', 0, 0, 
           '', 0, '��� ��Ÿ���', '', '0', 
           1, GETDATE(), 0, 1021351, 0 
      FROM #BaseData AS A 
     WHERE A.WorkingTag IN ( 'U','A' ) 
    
    
    INSERT INTO _TLGInOutDailyItem 
    (
        CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
        InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
        UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
        EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
        IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
        LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
        ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
    ) 
    
    SELECT @CompanySeq, 30, A.InOutSeq, 1, A.SubItemSeq, 
           '��� ��Ÿ���', NULL, NULL, 0, A.OutWHSeq, 
           B.UnitSeq, A.SubQty, A.SubQty, 0, 0, 
           0, 8023003, 8025009, '', '', 
           '', 0, 0, 0, 0, 
           1, GETDATE(), NULL, NULL, NULL, 
           NULL, NULL, NULL, 1021351
      FROM #BaseData AS A 
      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
     WHERE A.WorkingTag IN ( 'U','A' ) 
    
    INSERT INTO KPX_TPDSFCProdPackReportRelation 
    (
        CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
        InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
    )
    SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 6, 80, 
           A.InOutSeq, 1, 1, GETDATE() 
      FROM #BaseData AS A 
     WHERE A.WorkingTag = 'A'
    ---------------------------------------------------------------------------------
    -- ��� ��Ÿ���, END 
    ---------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------------------------------------
    -- ���� ���̺� ���� 
    ------------------------------------------------------------------------------------------------------------------------
    DELETE B 
      FROM #BaseData AS A 
      JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND B.WorkOrderSeq = A.WorkOrderSeq 
                                                  AND B.WorkOrderSerl = A.WorkOrderSerl 
                                                    ) 
     WHERE A.WorkingTag = 'D' 
    ------------------------------------------------------------------------------------------------------------------------
    -- ���� ���̺� ����, END  
    ------------------------------------------------------------------------------------------------------------------------    
    
    --select * from #BaseData
    ------------------------------------------------------------------------------------------------------------------------    
    -- ������� 
    ------------------------------------------------------------------------------------------------------------------------    
    CREATE TABLE #KPX_TPDSFCProdPackReport         
    (        
        IDX_NO              INT IDENTITY,         
        CompanySeq          INT,         
        PackReportSeq       INT,         
        FactUnit            INT,         
        PackDate            NCHAR(8),         
        ReportNo            NVARCHAR(100),         
        OutWHSeq            INT,         
        InWHSeq             INT,         
        UMProgType          INT,         
        DrumOutWHSeq        INT,         
        Remark              NVARCHAR(100),         
        LastUserSeq         INT        
    )         
            
    CREATE TABLE #KPX_TPDSFCProdPackReportItem         
    (        
        IDX_NO              INT IDENTITY,         
        CompanySeq          INT,         
        PackReportSeq       INT,         
        PackReportSerl      INT,         
        ItemSeq             INT,         
        UnitSeq             INT,         
        Qty                 DECIMAL(19,5),         
        LotNo               NVARCHAR(100),         
        OutLotNo            NVARCHAR(100),         
        Remark              NVARCHAR(100),         
        SubItemSeq          INT,         
        SubUnitSeq          INT,         
        SubQty              DECIMAL(19,5),         
        HambaQty            DECIMAL(19,5),         
        PackOrderSeq        INT,         
        PackOrderSerl       INT,         
        LastUserSeq         INT         
    )      
    CREATE TABLE #KPX_TPDSFCProdPackReportLog       
    (      
        IDX_NO          INT IDENTITY,       
        WorkingTag      NCHAR(1),       
        Status          INT,       
        PackReportSeq   INT      
    )     
    CREATE TABLE #KPX_TPDSFCProdPackReportItemLog       
    (      
        IDX_NO          INT IDENTITY,       
        WorkingTag      NCHAR(1),       
        Status          INT,       
        PackReportSeq   INT,      
        PackReportSerl   INT      
    ) 
    DECLARE @TableColumns NVARCHAR(MAX), 
            @ReportNo     NVARCHAR(50) 
    
    -- ���� ���� ������ �α�         
    INSERT INTO #KPX_TPDSFCProdPackReportLog ( WorkingTag, Status, PackReportSeq )         
    SELECT A.WorkingTag, 0, C.PackReportSeq        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
      JOIN KPX_TPDSFCProdPackReport     AS C ON ( C.CompanySeq = @CompanySeq AND C.PackReportSeq = B.PackReportSeq )         
            
    -- ������ �α�           
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackReport')            
                  
    EXEC _SCOMLog @CompanySeq   ,                
                  1      ,                
                  'KPX_TPDSFCProdPackReport'    , -- ���̺��                
                  '#KPX_TPDSFCProdPackReportLog'    , -- �ӽ� ���̺��                
                  'PackReportSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )                
                  @TableColumns , '', 1  -- ���̺� ��� �ʵ��           
            
                
    INSERT INTO #KPX_TPDSFCProdPackReportItemLog ( WorkingTag, Status, PackReportSeq, PackReportSerl )         
    SELECT A.WorkingTag, 0, B.PackReportSeq, B.PackReportSerl        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
                
    -- ������ �α�           
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackReportItem')            
                  
    EXEC _SCOMLog @CompanySeq   ,                
                  1      ,                
                  'KPX_TPDSFCProdPackReportItem'    , -- ���̺��                
                  '#KPX_TPDSFCProdPackReportItemLog'    , -- �ӽ� ���̺��                
                  'PackReportSeq,PackReportSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )                
                  @TableColumns , '', 1  -- ���̺� ��� �ʵ��           
    
    DELETE C         
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
      JOIN KPX_TPDSFCProdPackReport     AS C ON ( C.CompanySeq = @CompanySeq AND C.PackReportSeq = B.PackReportSeq )         
     WHERE A.WorkingTag IN ( 'U', 'D' )   
                 
                
    DELETE B        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
     WHERE A.WorkingTag IN ( 'U', 'D' )   
    
    -- ������ ������ #Temp
    INSERT INTO #KPX_TPDSFCProdPackReport         
    (        
        CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,         
        OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,         
        LastUserSeq         
    )        
    SELECT @CompanySeq, 0, A.FactUnit, WorkEndDate, '',         
           B.OutWHSeq, B.InWHSeq, B.UMProgType, B.SubOutWHSeq, B.Remark,         
           B.LastUserSeq        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackOrder AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq )         
     WHERE A.WorkingTag IN ( 'U', 'A' )   
    
    -- ������ ������ #Temp
    INSERT INTO #KPX_TPDSFCProdPackReportItem         
    (        
        CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,         
        Qty, LotNo, OutLotNo, Remark, SubItemSeq,         
        SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,         
        LastUserSeq         
    )        
    SELECT @CompanySeq, 0, 0, A.GoodItemSeq, B.UnitSeq,         
           A.RealProdQty, B.LotNo, B.OutLotNo, B.Remark, B.SubItemSeq,         
           B.SubUnitSeq, ISNULL(A.SubQty,0), A.HambaDrainQty, A.WorkOrderSeq, A.WorkOrderSerl,         
           B.LastUserSeq        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
     WHERE A.WorkingTag IN ( 'U', 'A' )   
    
    SELECT @Count = (SELECT COUNT(1) FROM #BaseData)
    
    SELECT @Seq = 0         
    -- Ű�������ڵ�κ� ����        
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPDSFCProdPackReport', 'PackReportSeq', @Count
    
            
    UPDATE A         
       SET PackReportSeq = @Seq + IDX_NO      
      FROM #KPX_TPDSFCProdPackReport AS A         

    UPDATE A         
       SET PackReportSeq = @Seq + IDX_NO,         
           PackReportSerl = 1     
      FROM #KPX_TPDSFCProdPackReportItem AS A          
    
    
    SELECT @Cnt = 1 
    
    -- ��ȣ ä�� 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @Date = PackDate 
          FROM #KPX_TPDSFCProdPackReport  
        
        EXEC dbo._SCOMCreateNo 'PD', 'KPX_TPDSFCProdPackReport', @CompanySeq, 0, @Date, @ReportNo OUTPUT 
        
        UPDATE A 
           SET ReportNo = @ReportNo 
          FROM #KPX_TPDSFCProdPackReport AS A 
         WHERE IDX_NO = @Cnt 
        
        
        
        IF @Cnt >= (SELECT ISNULL(MAX(IDX_NO),0) FROM #BaseData)
        BEGIN
            BREAK 
        END 
        ELSE 
        BEGIN 
            SELECT @Cnt = @Cnt + 1 
        END 
    
    END 
                
    INSERT INTO KPX_TPDSFCProdPackReport         
    (        
        CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,         
        OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,         
        LastUserSeq, LastDateTime         
    )        
    SELECT CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,         
           OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,         
           LastUserSeq, GETDATE()         
      FROM #KPX_TPDSFCProdPackReport         
              
    INSERT INTO KPX_TPDSFCProdPackReportItem         
    (        
        CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,         
        Qty, LotNo, OutLotNo, Remark, SubItemSeq,         
        SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,         
        LastUserSeq, LastDateTime        
    )        
    SELECT CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,         
             Qty, LotNo, OutLotNo, Remark, SubItemSeq,         
           SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,         
           LastUserSeq, GETDATE()        
      FROM #KPX_TPDSFCProdPackReportItem       
    ------------------------------------------------------------------------------------------------------------------------    
    -- �������, END 
    ------------------------------------------------------------------------------------------------------------------------    
    
    --select GETDATE() 
    CREATE TABLE #TLGStockReSumCheck (WorkingTag NCHAR(1) NULL)
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 7583, 'DataBlock1', '#TLGStockReSumCheck'
    
     CREATE TABLE #TLGStockReSum (WorkingTag NCHAR(1) NULL)      
     ExEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 5248, 'DataBlock1', '#TLGStockReSum'     

    -- ��������� 
    DECLARE @XmlData NVARCHAR(MAX) 
    
    CREATE TABLE #Date 
    (
        IDX_NO      INT IDENTITY, 
        StdYM       NCHAR(6) 
    )
    
    INSERT INTO #Date (StdYM) 
    SELECT DISTINCT LEFT(WorkEndDate,6) AS StdYM 
      FROM #BaseData
     ORDER BY LEFT(WorkEndDate,6)
    
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT 'U' AS WorkingTag,         
                                                      A.IDX_NO AS IDX_NO, 
                                                      A.IDX_NO AS DataSeq,         
                                                      1 AS Selected,         
                                                      0 AS Status,         
                                                      A.StdYM AS InOutYM, 
                                                      0 AS UserSeq, 
                                                      0 AS SMInOutType
                                                 FROM #Date AS A 
                                                FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                 ))         

    

--    INSERT INTO #TLGStockReSumCheck 
--    EXEC _SLGReInOutStockCheck 
--         @xmlDocument  = @XmlData,           
--         @xmlFlags     = 2,           
--         @ServiceSeq   = 7583,           
--         @WorkingTag   = '',           
--         @CompanySeq   = @CompanySeq,           
--         @LanguageSeq  = 1,           
--         @UserSeq      = 1,           
--         @PgmSeq       = 1021351    
    
--select * from #TLGStockReSumCheck 

--return 
    
--    INSERT INTO #TLGStockReSum 
--    EXEC _SLGReInOutStockSum 
--         @xmlDocument  = @XmlData,           
--         @xmlFlags     = 2,           
--         @ServiceSeq   = 5248,           
--         @WorkingTag   = '',           
--         @CompanySeq   = @CompanySeq,           
--         @LanguageSeq  = 1,           
--         @UserSeq      = 1,           
--         @PgmSeq       = 1021351    
    
--    --select LEFT(WorkEndDate,6), SubItemSeq from #BaseData
--    --select GETDATE()  
    
    
--    return 

    /*
        
    exec _SLGReInOutStockCheck @xmlDocument=N'<ROOT>
      <DataBlock1>
        <WorkingTag>U</WorkingTag>
        <IDX_NO>12</IDX_NO>
        <DataSeq>1</DataSeq>
        <Status>0</Status>
        <Selected>0</Selected>
        <InOutYM>201512</InOutYM>
        <SMInOutType>0</SMInOutType>
        <UserSeq>50322</UserSeq>
        <TABLE_NAME>DataBlock1</TABLE_NAME>
      </DataBlock1>
    </ROOT>',@xmlFlags=2,@ServiceSeq=7583,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5956


    exec _SLGReInOutStockSum @xmlDocument=N'<ROOT>
      <DataBlock1>
        <WorkingTag>U</WorkingTag>
        <IDX_NO>11</IDX_NO>
        <DataSeq>1</DataSeq>
        <Selected>0</Selected>
        <Status>0</Status>
        <InOutYM>201511</InOutYM>
        <SMInOutType>0</SMInOutType>
        <UserSeq>0</UserSeq>
      </DataBlock1>
    </ROOT>',@xmlFlags=2,@ServiceSeq=5248,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=0,@PgmSeq=5956
    */

    
    --UPDATE B        
    --   SET B.ProcYn = '1'         
    --  FROM #BaseData AS A         
    --  JOIN KPX_TPDSFCWorkReport_POP AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq ) 
    
    SELECT B.*
      FROM #BaseData AS A 
      JOIN KPX_TPDSFCWorkReport_POP AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq ) 
    
    
    RETURN 
go 
begin tran 
EXEC KPXGC_SPDSFCProdPackReportSave_POP 1 
----select * from KPX_TPDSFCWorkReport_POP where seq = 4549 
------------select * from 
    
----select * From _TLGInOutDaily AS A where companyseq = 1 and pgmseq= 1021351 and convert(nchar(8),lastdatetime,112) = '20150804' 

----select * From _TLGInOutDailyItem AS A where companyseq = 1 and pgmseq= 1021351 and convert(nchar(8),lastdatetime,112) = '20150804' 
    
ROLLBACK  

