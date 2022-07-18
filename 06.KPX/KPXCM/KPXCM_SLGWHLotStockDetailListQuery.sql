IF OBJECT_ID('KPXCM_SLGWHLotStockDetailListQuery') IS NOT NULL 
    DROP PROC KPXCM_SLGWHLotStockDetailListQuery
GO 

-- v2015.10.14
  /*************************************************************************************************        
  ��  �� - â�� LOT��������ȸ  
  �ۼ��� - 2009.7 : CREATED BY ���ظ�    
 *************************************************************************************************/        
 CREATE PROC KPXCM_SLGWHLotStockDetailListQuery      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
     DECLARE   @docHandle          INT,  
               @BizUnit            INT,  
               @FactUnit           INT,  
               @WHSeq              INT,  
               @FunctionWHSeq      INT,  
               @SMWHKind           INT,  
               @DateFr             NCHAR(8),  
               @DateTo             NCHAR(8),  
               @AssetSeq           INT,  
               @LotNo              NVARCHAR(30),
               @ItemName           NVARCHAR(200),  
               @ItemNo             NVARCHAR(100),  
               @Spec               NVARCHAR(100),  
               @ItemSeq            INT,  
               @ConvUnitSeq        INT,  
               @IsSubInclude       NCHAR(1),  
               @IsUnitQry          NCHAR(1),  
               @IsSubDisplay       NCHAR(1),  
               @QryType            NCHAR(1),  
               @IsTrustCust        NCHAR(1),  
               @CustSeq            INT  
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
   
   
     SELECT  @BizUnit            = ISNULL(BizUnit,0),  
             @FactUnit           = ISNULL(FactUnit,0),  
             @DateFr             = ISNULL(DateFr,''),  
             @DateTo             = ISNULL(DateTo,''),  
             @WHSeq              = ISNULL(WHSeq,0),  
             @SMWHKind           = ISNULL(SMWHKind,0),  
             @LotNo              = ISNULL(LotNo, ''),
             @ItemSeq            = ISNULL(ItemSeq,0),  
             @CustSeq            = ISNULL(CustSeq,0),  
             @IsSubInclude       = ISNULL(IsSubInclude,''),  
             @IsUnitQry          = ISNULL(IsUnitQry,''),  
             @IsSubDisplay       = ISNULL(IsSubDisplay,''),  
             @QryType            = ISNULL(QryType,''),  
             @IsTrustCust        = ISNULL(IsTrustCust,'')  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
     WITH (  BizUnit        INT,  
             FactUnit       INT,  
             DateFr         NCHAR(8),  
             DateTo         NCHAR(8),  
             WHSeq          INT,  
             SMWHKind       INT,  
             LotNo          NVARCHAR(30),
             ItemSeq        INT,     
             CustSeq        INT,     
             IsSubInclude   NCHAR(1),  
             IsUnitQry      NCHAR(1),     
             IsSubDisplay   NCHAR(1),  
             QryType        NCHAR(1),  
             IsTrustCust    NCHAR(1))   
   
   
     SELECT  @BizUnit            = ISNULL(@BizUnit,0),  
             @FactUnit           = ISNULL(@FactUnit,0),  
             @DateFr             = ISNULL(@DateFr,''),  
             @DateTo             = ISNULL(@DateTo,''),  
             @WHSeq              = ISNULL(@WHSeq,0),  
             @SMWHKind           = ISNULL(@SMWHKind,0),  
             @LotNo              = ISNULL(@LotNo, ''),
             @ItemSeq            = ISNULL(@ItemSeq,0),  
             @CustSeq            = ISNULL(@CustSeq,0),  
             @IsSubInclude       = ISNULL(@IsSubInclude,''),  
             @IsUnitQry          = ISNULL(@IsUnitQry,''),  
             @IsSubDisplay       = ISNULL(@IsSubDisplay,''),  
             @QryType            = ISNULL(@QryType,''),  
             @IsTrustCust        = ISNULL(@IsTrustCust,'')  
   
   
     CREATE TABLE #GetInOutLot
     (  
         LotNo  NVARCHAR(30),
         ItemSeq    INT  
     )  
       
     CREATE TABLE #GetInOutDetailLotStock   
     (
         IDX_NO          INT IDENTITY,  
         WHSeq           INT,  
         FunctionWHSeq   INT,  
         LotNo           NVARCHAR(30),
         ItemSeq         INT,  
         UnitSeq         INT,  
         InOutDate       NCHAR(8),  
         InOutType       INT,  
         InOutSeq        INT,  
         InOutSerl       INT,  
         InOutNo         NVARCHAR(20),  
         InOutKind       INT,  
         InOutDetailKind INT,  
         InQty           DECIMAL(19,5),  
         OutQty          DECIMAL(19,5),  
         STDInQty        DECIMAL(19,5),  
         STDOutQty       DECIMAL(19,5)  
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
   
     CREATE TABLE #WHDetailStock  
     (  
         IDX        INT IDENTITY,  
         InOutDate  NCHAR(8),  
         InOutName  NVARCHAR(10),  
         InOutKindName       NVARCHAR(100),  
         InOutDetailKindName NVARCHAR(100),  
         WHKindName          NVARCHAR(100),  
         FunctionWHName      NVARCHAR(100),  
         UnitName            NVARCHAR(30),  
         InOutKind        INT,  
         InOutDetailKind  INT,  
         FunctionWHSeq    INT,  
         UnitSeq          INT,  
         SMWHKind         INT,  
         InQty            DECIMAL(19,5),  
         OutQty           DECIMAL(19,5),  
         StockQty         DECIMAL(19,5),  
         InOutType        INT,  
         InOutSeq         INT,  
         InOutSerl        INT,  
         InOutNo          NVARCHAR(30),
         Cnt              NCHAR(1),
         JumpOutPgmId     NVARCHAR(100), 
         ColumnName       NVARCHAR(50)
     )  
   
   
     IF EXISTS (SELECT 1 FROM _TDAItem AS A JOIN _TDAItemAsset AS B ON A.CompanySeq = B.CompanySeq AND A.AssetSeq = B.AssetSeq  
                 WHERE A.CompanySeq = @CompanySeq AND A.ItemSeq = @ItemSeq AND B.IsQty <> '1')
     BEGIN
         INSERT INTO #GetInOutLot
         SELECT @LotNo, @ItemSeq  
     END
   
    
     
      -- â����� ��������  (�̿�)
     EXEC _SLGGetInOutLotStock   @CompanySeq   = @CompanySeq,   -- �����ڵ�      
                                 @BizUnit      = @BizUnit,      -- ����ι�      
                                 @FactUnit     = @FactUnit,     -- ��������      
                                 @DateFr       = @DateFr,       -- ��ȸ�ⰣFr      
                                 @DateTo       = @DateTo,       -- ��ȸ�ⰣTo      
                                 @WHSeq        = @WHSeq,        -- â������      
                                 @SMWHKind     = @SMWHKind,     -- â���к� ��ȸ      
                                 @CustSeq      = @CustSeq,      -- ��Ź�ŷ�ó      
                                 @IsTrustCust  = @IsTrustCust,  -- ��Ź����      
                                 @IsSubDisplay = @IsSubDisplay, -- ���â�� ��ȸ      
                                 @IsUnitQry    = @IsUnitQry,    -- ������ ��ȸ      
                                 @QryType      = @QryType       -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������      
   
     -- â����� ��������  
     EXEC _SLGGetInOutDetailLotStock     @CompanySeq   = @CompanySeq,   -- �����ڵ�  
                                         @BizUnit      = @BizUnit,      -- ����ι�  
                                         @FactUnit     = @FactUnit,     -- ��������  
                                         @DateFr       = @DateFr,       -- ��ȸ�ⰣFr  
                @DateTo       = @DateTo,       -- ��ȸ�ⰣTo  
                                         @WHSeq        = @WHSeq,        -- â������  
                                         @SMWHKind     = @SMWHKind,     -- â���к� ��ȸ  
                                         @CustSeq      = @CustSeq,      -- ��Ź�ŷ�ó  
                                         @IsTrustCust  = @IsTrustCust,  -- ��Ź����  
                                         @IsSubInclude = @IsSubInclude, -- ���â�� ����  
                                         @IsSubDisplay = @IsSubDisplay, -- ���â�� ��ȸ  
                                         @IsUnitQry    = @IsUnitQry,    -- ������ ��ȸ  
                                         @QryType      = @QryType       -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������  
   
      INSERT INTO #WHDetailStock(InOutDate, InOutName, InOutKindName, InOutDetailKindName, WHKindName,  
                                 FunctionWHName, UnitName, InOutKind, InOutDetailKind, FunctionWHSeq,  
                                 UnitSeq, SMWHKind, InQty, OutQty, StockQty,  
                                 InOutType, InOutSeq, InOutSerl, InOutNo,Cnt)  
     SELECT '','�̿����','','','',
            '',
            ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = B.UnitSeq), ''),0,0,0,
            B.UnitSeq, 0, SUM(A.STDPrevQty), 0, SUM(A.STDPrevQty), 0, 0, 0, '', '1'  
       FROM #GetInOutLotStock AS A
            JOIN _TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                            AND A.ItemSeq    = B.ItemSeq
      GROUP BY B.UnitSeq
  
     INSERT INTO #WHDetailStock(InOutDate, InOutName, InOutKindName, InOutDetailKindName, WHKindName,  
                                 FunctionWHName, UnitName, InOutKind, InOutDetailKind, FunctionWHSeq,  
                                 UnitSeq, SMWHKind, InQty, OutQty, StockQty,  
                                 InOutType, InOutSeq, InOutSerl, InOutNo,Cnt)  
     SELECT '','�Ⱓ��','','','',
            '',
            ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = B.UnitSeq), ''),0,0,0,
            B.UnitSeq, 0, SUM(A.STDInQty), SUM(A.STDOutQty), SUM(A.STDPrevQty) +  SUM(A.STDInQty) - SUM(A.STDOutQty), 0, 0, 0, '', '2'  
       FROM #GetInOutLotStock AS A
            JOIN _TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                            AND A.ItemSeq    = B.ItemSeq
      GROUP BY B.UnitSeq
  
     INSERT INTO #WHDetailStock(InOutDate, InOutName, InOutKindName, InOutDetailKindName, WHKindName,  
                                 FunctionWHName, UnitName, InOutKind, InOutDetailKind, FunctionWHSeq,  
                                 UnitSeq, SMWHKind, InQty, OutQty, StockQty,  
                                 InOutType, InOutSeq, InOutSerl, InOutNo,Cnt)  
     SELECT '','���','','','',
            '',
            ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = B.UnitSeq), ''),0,0,0,
            B.UnitSeq, 0, SUM(A.STDPrevQty) +  SUM(A.STDInQty) - SUM(A.STDOutQty), 0, 0, 0, 0, 0, '', '3'  
       FROM #GetInOutLotStock AS A
            JOIN _TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                            AND A.ItemSeq    = B.ItemSeq
      GROUP BY B.UnitSeq
  
     /*************** Get PgmId by InOutType [20130621 �ڼ�ȣ �߰�] ***************/
     
     -- _TLGInOutJumpPgmId�� InOutType�� PgmId�� �����մϴ�. -> ( sp_help _TLGInOutJumpPgmId / SELECT * FROM _TLGInOutJumpPgmId )
     -- �ϴ� #JumpPgmId�� �� ���а�(Local����, ��ǰ����, ������Ʈ����)�� ���� ������ ���� INSERT �� ��,
     -- SP�� �Ѿ�� DataBlock�� �����͸� �����Ͽ� ���� ���� UPDATE �� �ݴϴ�.
     -- �̷��� UPDATE �� #JumpPgmId�� ����, _TLGInOutJumpPgmId�� JOIN�Ͽ� PgmId�� ��ȸ�մϴ�.
      CREATE TABLE #JumpPgmId (
         IDX_NO      INT,
         SMInOutType INT,
         InOutType   INT,
         InOutSeq    INT,
         InOutSerl   INT,
         SMLocalKind INT,
         IsReturn    NCHAR(1),
         IsPMS       NCHAR(1),
         ColumnName  NVARCHAR(100)
     )
      INSERT INTO #JumpPgmId ( IDX_NO, SMInOutType, InOutType, InOutSeq, InOutSerl, SMLocalKind, IsReturn, IsPMS, ColumnName )
     SELECT A.IDX_NO, B.MinorSeq, A.InOutType, A.InOutSeq, A.InOutSerl, 8918001, '0', '0',
            CASE A.InOutType WHEN 10  THEN 'InvoiceSeq'    -- �ŷ���ǥ
                             WHEN 11  THEN 'InvoiceSeq'    -- ��ǰ��ǥ
                             WHEN 20  THEN 'BillSeq'       -- ����
                             WHEN 120 THEN 'SetInOutSeq'   -- ��Ʈ�԰�ó��
                             WHEN 130 THEN 'WorkReportSeq' -- �������
                             WHEN 140 THEN 'GoodInSeq'     -- �����԰�
                             WHEN 150 THEN 'OSPDelvInSeq'  -- �����԰�
                             WHEN 160 THEN 'DelvSeq'       -- ���ų�ǰ
                             WHEN 170 THEN 'DelvInSeq'     -- �����԰�
                             WHEN 180 THEN 'MatOutSeq'     -- �������
                             WHEN 190 THEN 'OSPDelvSeq'    -- ���ֳ�ǰ
                             WHEN 240 THEN 'DelvSeq'       -- �����԰�
                             WHEN 250 THEN 'MoveSeq'       -- ����ǰ�̵�
                             WHEN 171 THEN 'DelvInSeq'     -- ���Ź�ǰ
                             WHEN 280 THEN 'BadReworkSeq'  -- �԰��ĺҷ����۾�
                             WHEN 300 THEN 'DelvInSeq'     -- �����԰��ǰ
                             WHEN 350 THEN 'OSPDelvInSeq'  -- �����԰��ǰ
                             WHEN 370 THEN 'DelvInSeq'     -- ���Ź�ǰ
                             WHEN 310 THEN 'InOutSeq'      -- LOT��ü
                                      ELSE 'InOutSeq'      END AS ColumnName
       FROM #GetInOutDetailLotStock AS A
      LEFT OUTER JOIN _TDASMinor         AS B WITH(NOLOCK) ON A.InOutType  = B.MinorValue
                                                     AND B.MajorSeq   = 8042
                                                     AND B.CompanySeq = @CompanySeq
      /***** ������Ʈ ���� UPDATE *****/
     UPDATE #JumpPgmId
        SET IsPMS = '1'
       FROM #JumpPgmId                   AS A
            JOIN #GetInOutDetailLotStock AS B              ON A.InOutSeq   = B.InOutSeq
                                                          AND A.InOutSerl  = B.InOutSerl
                                                          AND A.InOutType  = B.InOutType
            JOIN _TSLInvoice             AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                          AND B.InOutType  IN (10, 11)
                                                          AND B.InOutSeq   = C.InvoiceSeq
      WHERE ISNULL(C.IsPJT, '') = '1'
         
 -- PJT���� �߰� 20130830  
   
 -- FrmPJTMMOutProc             ������Ʈ��������Է�  
 -- FrmPUDelv_PMSPur            ������Ʈ���ų�ǰ�Է�  
 -- FrmPUDelvIn_PMSPur          ������Ʈ�����԰��Է�  
 -- FrmPUDelvInReturn_PMSPur    ������Ʈ���Ź�ǰ�Է�  
 -- FrmSLBill2_PMSSales         ������Ʈ���ݰ�꼭�Է�(����)  
   
    /***** ������Ʈ ���� UPDATE *****/      -- PMS ���� ���� �߰�  
     UPDATE #JumpPgmId    
        SET IsPMS = '1'     
       FROM #JumpPgmId                      AS A    
            JOIN #GetInOutDetailLotStock    AS B              ON A.InOutSeq   = B.InOutSeq    
                                                             AND A.InOutSerl  = B.InOutSerl    
                                                             AND A.InOutType  = B.InOutType    
            LEFT OUTER JOIN _TSLSales       AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq     
                                                             AND A.InOutSeq   = C.SalesSeq    
                                                             AND A.InOutType  = 20    
            LEFT OUTER JOIN _TSLSalesitem   AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq     
                                                             AND C.SalesSeq   = D.SalesSeq  
   
      WHERE ISNULL(D.PjtSeq, 0) <> 0    
   
   
   
    /***** ������Ʈ ���� UPDATE *****/      -- PMS ���� ���ų�ǰ �߰�  
     UPDATE #JumpPgmId    
        SET IsPMS = '1'     
       FROM #JumpPgmId                      AS A    
            JOIN #GetInOutDetailLotStock    AS B              ON A.InOutSeq   = B.InOutSeq    
                                                             AND A.InOutSerl  = B.InOutSerl    
                                                             AND A.InOutType  = B.InOutType    
        LEFT OUTER JOIN _TpuDelv       AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq     
                                                              AND A.InOutSeq    = C.DelvSeq    
                                                             AND A.InOutType  = 160    
           
      WHERE ISNULL(C.IsPJT, '') = '1'    
               
   
    /***** ������Ʈ ���� UPDATE *****/      -- PMS ���� �����԰� �߰�  
     UPDATE #JumpPgmId    
        SET IsPMS = '1'     
       FROM #JumpPgmId                      AS A    
            JOIN #GetInOutDetailLotStock    AS B              ON A.InOutSeq   = B.InOutSeq    
                                                             AND A.InOutSerl  = B.InOutSerl    
                                                             AND A.InOutType  = B.InOutType    
            LEFT OUTER JOIN _TpuDelvIn       AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq     
                                                             AND A.InOutSeq   = C.DelvInSeq    
                                                             AND A.InOutType  = 170    
           
      WHERE ISNULL(C.IsPJT, '') = '1'    
        
     
     
    /***** ������Ʈ ���� UPDATE *****/      -- PMS ���� ������� �߰�  
     UPDATE #JumpPgmId    
        SET IsPMS = '1'     
       FROM #JumpPgmId                      AS A    
            JOIN #GetInOutDetailLotStock    AS B              ON A.InOutSeq   = B.InOutSeq    
                                                             AND A.InOutSerl  = B.InOutSerl    
                                                             AND A.InOutType  = B.InOutType    
            LEFT OUTER JOIN _TPDMMOutM       AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq     
                                                             AND A.InOutSeq   = C.MatOutSeq    
                                                             AND A.InOutType  = 180    
            LEFT OUTER JOIN _TPDMMOutItem   AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq     
                                                             AND C.MatOutSeq  = D.MatOutSeq  
   
      WHERE ISNULL(D.PjtSeq, 0) <> 0
      
      /***** ������Ʈ ���� UPDATE *****/      -- PMS ���� �����԰� 
      UPDATE #JumpPgmId    
         SET IsPMS = '1'     
       FROM #JumpPgmId                      AS A    
            JOIN #GetInOutDetailLotStock    AS B              ON A.InOutSeq   = B.InOutSeq    
                                                             AND A.InOutSerl  = B.InOutSerl    
                                                             AND A.InOutType  = B.InOutType    
            LEFT OUTER JOIN _TUIImpDelv       AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq     
                                                               AND A.InOutSeq   = C.DelvSeq    
                                                               AND A.InOutType  = 240    
            LEFT OUTER JOIN _TUIImpDelvItem   AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq     
                                                               AND C.DelvSeq  = D.DelvSeq  
   
      
      WHERE ISNULL(C.ISPJT, 0) <> 0
      /***** �������ⱸ�� UPDATE *****/
      -- �ŷ���ǥ(10) & ��ǰ��ǥ(11)
     UPDATE #JumpPgmId
        SET SMLocalKind = 8918002
       FROM #JumpPgmId                     AS A
            JOIN #GetInOutDetailLotStock   AS B              ON A.InOutSeq   = B.InOutSeq
                                                            AND A.InOutSerl  = B.InOutSerl
                                                            AND A.InOutType  = B.InOutType
            LEFT OUTER JOIN _TSLExpInvoice AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                            AND A.InOutType  IN (10, 11)
                                                            AND A.InOutSeq   = C.InvoiceSeq
      WHERE ISNULL(C.InvoiceSeq, 0) <> 0
      -- �ǸŸ���(20)
     UPDATE #JumpPgmId
        SET SMLocalKind = 8918002
       FROM #JumpPgmId                      AS A
            JOIN #GetInOutDetailLotStock    AS B              ON A.InOutSeq   = B.InOutSeq
                                                             AND A.InOutSerl  = B.InOutSerl
                                                             AND A.InOutType  = B.InOutType
            LEFT OUTER JOIN _TSLSales       AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq 
                                                             AND A.InOutSeq   = C.SalesSeq
                                                             AND A.InOutType  = 20
            LEFT OUTER JOIN _TDASMinorValue AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq
                                                             AND C.SMExpKind  = D.MinorSeq
                                                             AND D.Serl       = 1001
      WHERE D.ValueText <> '1'
  
     /*****  ��ǰ���� UPDATE *****/
     UPDATE #JumpPgmId
        SET IsReturn = '1'
       FROM #JumpPgmId                   AS A
            JOIN #GetInOutDetailLotStock AS B ON A.InOutSeq  = B.InOutSeq
                                             AND A.InOutSerl = B.InOutSerl
                                             AND A.InOutType = B.InOutType
      WHERE B.InOutType  = 180
        AND B.InOutKind <> 8023020
      
     /****************************************************************************/
  
     INSERT INTO #WHDetailStock(InOutDate, InOutName, InOutKindName, InOutDetailKindName, WHKindName,  
                                 FunctionWHName, UnitName, InOutKind, InOutDetailKind, FunctionWHSeq,  
                                 UnitSeq, SMWHKind, InQty, OutQty, StockQty,  
                                 InOutType, InOutSeq, InOutSerl, InOutNo,Cnt,JumpOutPgmId,ColumnName)
     SELECT  ISNULL(A.InOutDate,'') AS InOutDate,                               
             CASE WHEN A.InQty <> 0 THEN '�԰�'  
                  WHEN A.OutQty <> 0 THEN '���'  
                  ELSE '' END AS InOutName,  
             ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.InOutKind), '') AS InOutKindName,  
             ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.InOutDetailKind), '') AS InOutDetailKindName,  
             ISNULL((SELECT MinorName   
                       FROM _TDASMinor WITH (NOLOCK)  
                      WHERE CompanySeq = @CompanySeq   
                        AND MinorSeq = (CASE WHEN ISNULL(A.FunctionWHSeq,0) = 0 THEN ISNULL(B.SMWHKind,0) ELSE ISNULL(C.SMWHKind,0) END)),'') AS WHKindName,  
             ISNULL((SELECT WHName FROM _TDAWHSub WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = A.FunctionWHSeq), '') AS FunctionWHName,  
             CASE WHEN @IsUnitQry = '1' THEN ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq), '')   
                                        ELSE ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = D.UnitSeq), '') END AS UnitName,  
             ISNULL(A.InOutKind, 0) AS InOutKind,  
             ISNULL(A.InOutDetailKind, 0) AS InOutDetailKind,  
             ISNULL(A.FunctionWHSeq, 0) AS FunctionWHSeq,  
             CASE WHEN @IsUnitQry = '1' THEN ISNULL(A.UnitSeq, 0) ELSE ISNULL(D.UnitSeq, 0) END AS UnitSeq,  
             CASE WHEN ISNULL(A.FunctionWHSeq,0) = 0 THEN ISNULL(B.SMWHKind,0) ELSE ISNULL(C.SMWHKind,0) END AS SMWHKind,  
             CASE WHEN @IsUnitQry = '1' THEN ISNULL(A.InQty, 0) ELSE ISNULL(A.STDInQty, 0) END AS InQty,  
             CASE WHEN @IsUnitQry = '1' THEN ISNULL(A.OutQty, 0) ELSE ISNULL(A.STDOutQty, 0) END AS OutQty,  
             CASE WHEN @IsUnitQry = '1' THEN ISNULL(A.InQty, 0) - ISNULL(A.OutQty, 0) ELSE ISNULL(A.STDInQty, 0) - ISNULL(A.STDOutQty, 0) END AS StockQty,  
             ISNULL(A.InOutType,0) AS InOutType,  
             ISNULL(A.InOutSeq, 0) AS InOutSeq,  
             ISNULL(A.InOutSerl, 0) AS InOutSerl,  
             ISNULL(A.InOutNo, '') AS InOutNo, '4',
             '', 
             --P.PgmId AS JumpOutPgmId, -- 20130621 �ڼ�ȣ �߰�
             O.ColumnName
       FROM  #GetInOutDetailLotStock     AS A
       LEFT OUTER JOIN _TDAWH            AS B WITH (NOLOCK)  ON B.CompanySeq     = @CompanySeq  
                                                            AND A.WHSeq          = B.WHSeq  
       LEFT OUTER JOIN _TDAWHSub         AS C WITH (NOLOCK)  ON C.CompanySeq     = @CompanySeq  
                                                            AND A.FunctionWHSeq  = C.WHSeq  
       LEFT OUTER JOIN _TDAItem          AS D WITH (NOLOCK)  ON D.CompanySeq     = @CompanySeq  
                                                            AND A.ItemSeq        = D.ItemSeq
       JOIN #JumpPgmId                   AS O    ON A.InOutType   = O.InOutType 
                                                          AND A.InOutSeq    = O.InOutSeq 
                                                          AND A.InOutSerl   = O.InOutSerl 
                                                          AND A.IDX_NO      = O.IDX_NO
       LEFT OUTER JOIN _TLGInOutJumpPgmId           AS P WITH(NOLOCK) ON P.CompanySeq  = @CompanySeq -- JOIN -> LEFT OUTER JOIN ���� by����õ 
                                                          AND P.SMInOutType = O.SMInOutType
                                                          AND P.SMLocalKind = O.SMLocalKind
                                                          AND P.IsReturn    = O.IsReturn
                                                          AND P.IsPMS       = O.IsPMS
      ORDER BY A.InOutDate, A.InOutSeq, A.InOutSerl, A.InOutType, A.InOutKind  
   
   
      UPDATE #WHDetailStock  
         SET StockQty = Y.StockQty  
        FROM #WHDetailStock AS X   
             JOIN (SELECT A.IDX, SUM(B.StockQty) AS StockQty  
                     FROM #WHDetailStock AS A   
                          JOIN #WHDetailStock AS B ON A.IDX >= B.IDX  
                    WHERE B.CNT NOT IN (2,3)   
                    GROUP BY A.IDX) AS Y ON X.IDX = Y.IDX  
     
     -- �̿���� �� �Ⱓ����� ������ 0���� ������   
     UPDATE #WHDetailStock SET StockQty = 0 WHERE Cnt IN ('1','2')  
     
     -- �������� ����� ... 
     UPDATE #WHDetailStock SET StockQty = InQty WHERE Cnt = '3' 
      
  
     SELECT A.*, C.CustName
       FROM #WHDetailStock AS A
            LEFT OUTER JOIN _TLGInOutDaily AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                             AND B.InOutSeq   = A.InOutSeq
                                                             AND B.InOutType  = A.InOutType
            LEFT OUTER JOIN _TDACust       AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq
                                                             AND C.CustSeq    = B.CustSeq
      ORDER BY IDX
    
     RETURN
     go
     begin tran
exec KPXCM_SLGWHLotStockDetailListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <IsUnitQry>0</IsUnitQry>
    <IsSubDisplay>0</IsSubDisplay>
    <BizUnit>1</BizUnit>
    <BizUnitName>�췹ź�ι�</BizUnitName>
    <DateFr>20151002</DateFr>
    <DateTo>20151002</DateTo>
    <SMWHKind>8002001</SMWHKind>
    <WHKindName>�Ϲ�â��</WHKindName>
    <FactUnit>3</FactUnit>
    <FactUnitName>�췹ź</FactUnitName>
    <WHSeq>14</WHSeq>
    <WHName>(�췹ź)���η�â��</WHName>
    <CustSeq />
    <CustName />
    <LotNo>42110011</LotNo>
    <ItemSeq>1714</ItemSeq>
    <ItemName>B-8462</ItemName>
    <ItemNo>31190059</ItemNo>
    <IsSubInclude>1</IsSubInclude>
    <QryType>S</QryType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=5150,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1391
rollback 