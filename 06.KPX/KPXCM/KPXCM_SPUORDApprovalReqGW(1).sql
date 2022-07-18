IF OBJECT_ID('KPXCM_SPUORDApprovalReqGW') IS NOT NULL
    DROP PROC KPXCM_SPUORDApprovalReqGW
GO
/************************************************************
 ��  �� - ������-����ǰ�����ڰ���_KPXCM : 
 �ۼ��� - 20150705
 �ۼ��� - �ڻ���
 ������ - 
************************************************************/
CREATE PROC dbo.KPXCM_SPUORDApprovalReqGW                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    
    DECLARE  @docHandle         INT
            ,@ApproReqSeq       INT
            ,@TotDomAmt         DECIMAL(19,5)
            ,@TotCurAmt         DECIMAL(19,5)
            ,@Date              NCHAR(8)
            ,@DateFr            NCHAR(8)
            ,@DateTo            NCHAR(8)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT  @ApproReqSeq  = ApproReqSeq   
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
                ApproReqSeq   INT 
           )
/*=================================================================================================
=================================================================================================*/
  --1758,1759
SELECT @Date = ApproReqDate
FROM _TPUORDApprovalReq WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq
SELECT  @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,@Date),112)
       ,@DateFr = CONVERT(NCHAR(8),DATEADD(MM,-3,@Date),112)

-- ���ǰ�� 
CREATE TABLE #GetInOutItem
( 
    ItemSeq INT, 
    ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- ǰ��Һз�
    ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- ǰ���ߺз�
    ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- ǰ���з�
)
INSERT INTO #GetInOutItem(ItemSeq)
SELECT ItemSeq
FROM _TPUORDApprovalReqItem
WHERE CompanySeq = @CompanySeq
AND ApproReqSeq = @ApproReqSeq

-- �����
CREATE TABLE #GetInOutStock
(
    WHSeq           INT,
    FunctionWHSeq   INT,
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
-- ��������� 
CREATE TABLE #TLGInOutStock  
(  
    InOutType INT,  
    InOutSeq  INT,  
    InOutSerl INT,  
    DataKind  INT,  
    InOutSubSerl  INT,  
    InOut INT,  
    InOutDate NCHAR(8),  
    WHSeq INT,  
    FunctionWHSeq INT,  
    ItemSeq INT,  
    UnitSeq INT,  
    Qty DECIMAL(19,5),  
    StdQty DECIMAL(19,5),
    InOutKind INT,
    InOutDetailKind INT 
)

    -- â����� ��������
    EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq         -- �����ڵ�
                           ,@BizUnit      = 0                   -- ����ι�
                           ,@FactUnit     = 0                   -- ��������
                           ,@DateFr       = @DateFr             -- ��ȸ�ⰣFr
                           ,@DateTo       = @DateTo             -- ��ȸ�ⰣTo
                           ,@WHSeq        = 0                   -- â������
                           ,@SMWHKind     = 0                   -- â���� 
                           ,@CustSeq      = 0                   -- ��Ź�ŷ�ó
                           ,@IsTrustCust  = ''                  -- ��Ź����
                           ,@IsSubDisplay = 0                   -- ���â�� ��ȸ
                           ,@IsUnitQry    = 0                   -- ������ ��ȸ
                           ,@QryType      = 'S'                 -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������
                           ,@MngDeptSeq   = 0                   
                           ,@IsUseDetail  = '1'

  SELECT  @CompanySeq                 AS CompanySeq
         ,ItemSeq
         ,SUM(ISNULL(STDOutQty,0))    AS OutQty
    INTO #OutQty
    FROM #GetInOutStock
GROUP BY ItemSeq

TRUNCATE TABLE #GetInOutStock
TRUNCATE TABLE #TLGInOutStock

    -- â����� ��������
    EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq         -- �����ڵ�
                           ,@BizUnit      = 0                   -- ����ι�
                           ,@FactUnit     = 0                   -- ��������
                           ,@DateFr       = @Date               -- ��ȸ�ⰣFr
                           ,@DateTo       = @Date               -- ��ȸ�ⰣTo
                           ,@WHSeq        = 0                   -- â������
                           ,@SMWHKind     = 0                   -- â���� 
                           ,@CustSeq      = 0                   -- ��Ź�ŷ�ó
                           ,@IsTrustCust  = ''                  -- ��Ź����
                           ,@IsSubDisplay = 0                   -- ���â�� ��ȸ
                           ,@IsUnitQry    = 0                   -- ������ ��ȸ
                           ,@QryType      = 'S'                 -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������
                           ,@MngDeptSeq   = 0                   
                           ,@IsUseDetail  = '1'

  SELECT  @CompanySeq                   AS CompanySeq
         ,ItemSeq
         ,SUM(ISNULL(STDStockQty,0))    AS StockQty
    INTO #StockQty
    FROM #GetInOutStock 
GROUP BY ItemSeq



/*=================================================================================================
=================================================================================================*/
    
    
    
    SELECT ROW_NUMBER() OVER( ORDER BY B.ApproReqSeq, B.ApproReqSerl ) AS Num 
           ,ISNULL(H.ItemName       ,'')       AS ItemName
           ,ISNULL(H.ItemNo         ,'')       AS ItemNo
           ,ISNULL(H.Spec           ,'')       AS Spec
           ,ISNULL(B.Memo1          ,'')       AS PurPose              --�뵵
           ,ISNULL(B.Memo5          , 0)       AS PackingSeq           --���屸��
           ,ISNULL(I.MinorName      ,'')       AS PackingName          --���屸��
           ,ISNULL(M.Price          , 0)       AS CurentPrice          --������
           ,ISNULL(B.Memo7          , 0)       AS FirstPrice           --1��������
           ,(CASE WHEN ISNULL(M.Price, 0) = 0
                 THEN ISNULL(B.Memo7, 0)
                 ELSE ISNULL(M.Price, 0)
            END)-ISNULL(B.Price, 0)            AS DiffPrice --�ܰ�����        => ABS???
           ,CASE WHEN ISNULL(M.Price, 0)=0
                 THEN 0
                 ELSE ((CASE WHEN ISNULL(M.Price, 0)=0
                             THEN ISNULL(B.Memo7, 0)
                             ELSE ISNULL(M.Price, 0)
                        END)-ISNULL(B.Price, 0))/ISNULL(M.Price, 0)
            END AS TransRate               --������(%)
           ,ISNULL(B.Qty            , 0)       AS Qty                --����
           ,ISNULL(B.DelvDate       ,'')       AS DelvDate           --�����û��
           ,ISNULL(J.TotCurAmt      , 0)       AS TotCurAmt          --���űݾ�
           ,ISNULL(N.OutQty         , 0)       AS OutQty             --��ջ�뷮
           ,ISNULL(O.StockQty       , 0)       AS StockQty           --�����

      FROM _TPUORDApprovalReq                  AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TPUORDApprovalReqItem              AS B WITH(NOLOCK)ON A.CompanySeq    = B.CompanySeq
                                                                          AND A.ApproReqSeq   = B.ApproReqSeq
      LEFT OUTER JOIN _TDADept                            AS C WITH(NOLOCK)ON A.CompanySeq    = C.CompanySeq
                                                                          AND A.DeptSeq       = C.DeptSeq
      LEFT OUTER JOIN _TDACurr                            AS D WITH(NOLOCK)ON B.CompanySeq    = D.CompanySeq
                                                                          AND B.CurrSeq       = D.CurrSeq
      LEFT OUTER JOIN _TDAEmp                             AS E WITH(NOLOCK)ON A.CompanySeq    = E.CompanySeq
                                                                          AND A.EmpSeq        = E.EmpSeq
      LEFT OUTER JOIN _TDACust                            AS F WITH(NOLOCK)ON B.CompanySeq    = F.CompanySeq
                                                                          AND B.CustSeq       = F.CustSeq
      LEFT OUTER JOIN _TDACust                            AS G WITH(NOLOCK)ON B.CompanySeq    = G.CompanySeq
                                                                          AND B.MakerSeq      = G.CustSeq
      LEFT OUTER JOIN _TDAItem                            AS H WITH(NOLOCK)ON B.CompanySeq    = H.CompanySeq
                                                                          AND B.ItemSeq       = H.ItemSeq
      LEFT OUTER JOIN _TDAUMinor                          AS I WITH(NOLOCK)ON B.CompanySeq    = I.CompanySeq
                                                                          AND B.Memo5         = I.MinorSeq
      LEFT OUTER JOIN (
                          SELECT  CompanySeq
                                 ,ApproReqSeq
                                 ,MAX(UnitSeq)            AS UnitSeq
                                 ,SUM(DomAmt + DomVAT)    AS TotDomAmt
                                 ,SUM(CurAmt + CurVAT)    AS TotCurAmt
                            FROM _TPUORDApprovalReqItem
                           WHERE CompanySeq  = @CompanySeq
                             AND ApproReqSeq = @ApproReqSeq
                        GROUP BY CompanySeq,ApproReqSeq
                      )                                   AS J             ON A.CompanySeq    = J.CompanySeq
                                                                          AND A.ApproReqSeq   = J.ApproReqSeq
      LEFT OUTER JOIN _TDAUnit                            AS K WITH(NOLOCK)ON J.CompanySeq    = K.CompanySeq
                                                                          AND J.UnitSeq       = K.UnitSeq
      LEFT OUTER JOIN (
                          SELECT X.CompanySeq,MAX(X.DelvInSeq) AS DelvInSeq,X.DelvInSerl,X.ItemSeq
                            FROM _TPUDelvIn       AS Z
                            JOIN _TPUDelvInItem   AS X WITH(NOLOCK)ON Z.CompanySeq = X.CompanySeq
                                                                  AND Z.DelvInSeq  = X.DelvInSeq
                           WHERE Z.CompanySeq = @CompanySeq
                             AND Z.DelvInDate <= (SELECT ApproReqDate     FROM _TPUORDApprovalReq     WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)
                             AND X.ItemSeq    IN (SELECT DISTINCT ItemSeq FROM _TPUORDApprovalReqItem WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)      --��ȭ�������� ���߿� Ȯ���ϱ�
                        GROUP BY X.CompanySeq,X.DelvInSerl,X.ItemSeq
                      )                                   AS L             ON B.CompanySeq    = L.CompanySeq
                                                                          AND B.ItemSeq       = L.ItemSeq
      LEFT OUTER JOIN _TPUDelvInItem                      AS M WITH(NOLOCK)ON L.CompanySeq    = M.CompanySeq
                                                                          AND L.DelvInSeq     = M.DelvInSeq
                                                                          AND L.DelvInSerl    = M.DelvInSerl
      LEFT OUTER JOIN #OutQty                             AS N WITH(NOLOCK)ON B.CompanySeq    = N.CompanySeq
                                                                          AND B.ItemSeq       = N.ItemSeq
      LEFT OUTER JOIN #StockQty                           AS O WITH(NOLOCK)ON B.CompanySeq    = O.CompanySeq
                                                                          AND B.ItemSeq       = O.ItemSeq
                                                                          
     WHERE A.CompanySeq    = @CompanySeq
       AND A.ApproReqSeq   = @ApproReqSeq


/*=================================================================================================
=================================================================================================*/    
RETURN
go

EXEC _SCOMGroupWarePrint 2, 1, 1, 1025093, 'ApprovalReq_CM', '13', ''