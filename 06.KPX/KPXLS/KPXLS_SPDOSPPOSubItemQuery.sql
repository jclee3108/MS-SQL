IF OBJECT_ID('KPXLS_SPDOSPPOSubItemQuery') IS NOT NULL 
    DROP PROC KPXLS_SPDOSPPOSubItemQuery
GO 

-- v2016.05.23 

/*************************************************************************************************      
 ��  �� - ���ֹ��� 
 �ۼ��� - 2008.10.20 : CREATEd by �뿵��
 ������ - 2012.04.05 : Modify by snheo  
          ����ó��� �������� ���� �߰�
		  2013.03.08 : Modify by snheo
		  ��������� �������� �κп��� ���� ������ �ƴ� ���ش����� ǥ���ϰ� �־ ����
		  2014.02.12 : Modify by yhkim
		  ����ó��� ������ ���ش����� �°� ���������� ����
 ������ - 2014.04.04 : Modify By ���й�: â���Ͽ��� ����庰�� �������â�� ����ϵ��� �����ϰ� �Ǿ, ����ó��� �����ö��� ������� üũ
        - 2015.05.22 : Modify By ������: Order by �߰�   
*************************************************************************************************/      
CREATE PROCEDURE KPXLS_SPDOSPPOSubItemQuery
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS         
    DECLARE   @docHandle   INT,      
              @BizUnit     INT,
              @OSPPOSeq    INT,
              @OSPMatSerl  INT,
              @OSPRev      INT,
              @ItemSeq     INT,
              @ItemNo      NVARCHAR(100),
              @CustSeq     INT,
              @FRDate      NCHAR(8),
              @TODate      NCHAR(8),
              @pItemType   INT,
              @pLast       INT,
              @FactUnit    INT, 
              @WHSeq       INT,
              @CurrDate      NCHAR(8)   
 
    --EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    --SELECT 
    --        @OSPPOSeq   = ISNULL(OSPPOSeq,0)
    --FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)         
    --WITH ( OSPPOSeq INT)        
    
    -- ���� ����Ÿ ��� ����
    CREATE TABLE #TPDOSPPOItemMat (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TPDOSPPOItemMat'     
    IF @@ERROR <> 0 RETURN    

    SELECT @OSPMatSerl = OSPMatSerl FROM #TPDOSPPOItemMat


    SELECT @CurrDate = CONVERT(NCHAR(8), GETDATE(), 112)  
    /******************************************************************************************
     ����ó ��� �������� ����
    *******************************************************************************************/
    
    --����ó��� �������� ���� ����ó ������
    SELECT @CustSeq = A.CustSeq,
           @FactUnit = A.FactUnit
      FROM _TPDOSPPO AS A 
                JOIN #TPDOSPPOItemMat AS B  ON A.OSPPOSeq = B.OSPPOSeq
     WHERE A.CompanySeq = @CompanySeq 

    --�ش� ��Ź�ŷ�ó�� ���� â���ڵ� ���ϱ�  
    SELECT @WHSeq = WHSeq   
      FROM _TDAWH   
     WHERE CompanySeq = @CompanySeq  
       AND CommissionCustSeq = @CustSeq   
       AND FactUnit = @FactUnit --���й�20140404:â���Ͽ��� ����庰�� �������â�� ����ϵ��� �����ϰ� �Ǿ, ����ó��� �����ö��� ������� üũ   


    CREATE TABLE #GetInOutItem
    (ItemSeq INT)

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
    
    INSERT INTO #GetInOutItem
    SELECT DISTINCT H.ItemSeq 
      FROM _TPDOSPPOItemMat AS H  
                JOIN #TPDOSPPOItemMat AS T               ON H.OSPPOSeq = T.OSPPOSeq   
                                                        AND (@OSPMatSerl IS NULL OR H.OSPMatSerl = T.OSPMatSerl) 
    WHERE H.CompanySeq = @CompanySeq 

  --  SELECT * FROM #GetInOutItem

    EXEC _SLGGetInOutStock    
        @CompanySeq    = @CompanySeq,       -- �����ڵ�    
        @BizUnit       = 0,     -- ����ι�    
        @FactUnit      = @FactUnit,       -- ��������    
        @DateFr        = @CurrDate, -- ��ȸ�ⰣFr    
        @DateTo        = @CurrDate, -- ��ȸ�ⰣTo    
        @WHSeq         = @WHSeq,       -- â������    
        @SMWHKind      = 0,       -- â���к� ��ȸ    
        @CustSeq       = 0,       -- ��Ź�ŷ�ó    
        @IsSubDisplay  = '', -- ���â�� ��ȸ    
        @IsUnitQry     = '0', -- ������ ��ȸ    
        @QryType       = 'S'  -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������    

    /*************************************************************************************************************/

    
    SELECT  
        K.WorkOrderNo  AS WorkOrderNo   ,
        D.ItemNo       AS AssyItemNo    , -- ����ǰ��
        D.ItemName     AS AssyItemName  , -- ����ǰ��
        D.Spec         AS AssySpec      , -- ���ֱ԰�
        E.UnitName     AS AssyUnitName  , -- ���ִ���
        J.ItemNo       AS MatItemNo     , -- �����ȣ
        J.ItemName     AS MatItemName   , -- �����
        J.Spec         AS MatSpec       , -- ����԰�
        N.UnitName     AS MatUnitName   , -- �������
        H.QtyPerOne    AS Qty     , -- ����ҿ䷮
        H.Qty          AS ReqQty        , -- �����û����
        ISNULL(G.STDStockQty, 0)     AS StockQty      , -- ����ó���
        H.Remark       AS Remark        , -- ���
        H.StdUnitSeq   AS StdUnitSeq    , -- ���ش����ڵ�
        L.UnitName     AS StdUnitName   , -- ���ش���
        H.StdUnitQty   AS StdUnitQty    , -- ���ش�������
        H.ItemSeq      AS MatItemSeq    , -- ���系���ڵ�
        H.UnitSeq      AS UnitSeq       , -- ����
        H.IsSale        ,
        H.Price         ,

        K.WorkOrderSeq AS WorkOrderSeq  ,
        K.WorkOrderSerl AS WorkOrderSerl, 
        A.OSPAssySeq   AS AssySeq       ,
        A.OSPPOSeq     AS OSPPOSeq      ,
        A.OSPPOSerl    AS OSPPOSerl     ,
        H.OSPMatSerl   AS OSPMatSerl    ,
        A.OSPPOSeq     AS FromSeq      ,
        A.OSPPOSerl    AS FromSerl     
        --,P.DelvReqSeq     AS FromSeq
        --,P.DelvReqSerl    AS FromSerl
        ,O.OSPMatSerl                AS FromSubSerl
        ,P.DelvReqSeq     AS Memo4
        ,P.DelvReqSerl    AS Memo5 
        
    FROM _TPDOSPPOItemMat                               AS H
                     JOIN #TPDOSPPOItemMat              AS T               ON H.OSPPOSeq = T.OSPPOSeq 
                                                                          AND (@OSPMatSerl IS NULL OR H.OSPMatSerl = T.OSPMatSerl)
                     JOIN _TPDOSPPOItem                 AS A  WITH(NOLOCK) ON H.CompanySeq = A.CompanySeq
                                                                          AND H.OSPPOSeq = A.OSPPOSeq
                                                                          AND H.OSPPOSerl = A.OSPPOSerl
                     JOIN _TPDOSPPO                     AS M  WITH(NOLOCK) ON A.CompanySeq  = M.CompanySeq
                                                                          AND A.OSPPOSeq    = M.OSPPOSeq
          LEFT OUTER JOIN _TPDSFCWorkOrder              AS K  WITH(NOLOCK) ON A.CompanySeq  = K.CompanySeq
                                                                          AND A.WorkOrderSeq= K.WorkOrderSeq  
                                                                          AND A.WorkOrderSerl = K.WorkOrderSerl
          LEFT OUTER JOIN _TDAItem                      AS D  WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq
                                                                          AND A.OSPAssySeq  = D.ItemSeq  
          LEFT OUTER JOIN _TDAUnit                      AS E  WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq
                                                                          AND D.UnitSeq     = E.UnitSeq
          LEFT OUTER JOIN _TDAItem                      AS J  WITH(NOLOCK) ON H.CompanySeq  = J.CompanySeq
                                                                          AND H.ItemSeq  = J.ItemSeq  
          LEFT OUTER JOIN _TDAUnit                      AS L  WITH(NOLOCK) ON H.CompanySeq  = L.CompanySeq
                                                                          AND H.StdUnitSeq     = L.UnitSeq
		  LEFT OUTER JOIN _TDAUnit		                AS N WITH(NOLOCK) ON H.CompanySeq     = N.CompanySeq 
											                				 AND H.UnitSeq        = N.UnitSeq
        LEFT OUTER JOIN #GetInOutStock                AS G               ON H.ItemSeq     = G.ItemSeq
                                                                          --AND H.StdUnitSeq  = G.UnitSeq     -- H.UnitSeq => H.StdUnitSeq  �� ���������� ���� 2014.02.12 �����
          LEFT OUTER JOIN KPXLS_TSLDelvRequest          AS O WITH(NOLOCK)ON O.CompanySeq            = A.CompanySeq
                                                                        AND O.DVReqSeq              = A.OSPPOSeq
                                                                        AND O.DVReqSerl             = A.OSPPOSerl
                                                                        AND ISNULL(O.FromPgmSeq,0)  IN(1036,1028455)
          LEFT OUTER JOIN KPXLS_TSLDelvRequestItem      AS P WITH(NOLOCK)ON @CompanySeq             = P.CompanySeq
                                                                        AND T.DelvReqSeq            = P.DelvReqSeq
                                                                        AND T.DelvReqSerl           = P.DelvReqSerl
                                                                        
    WHERE A.CompanySeq  = @CompanySeq
    ORDER BY T.IDX_NO
    
RETURN
GO


