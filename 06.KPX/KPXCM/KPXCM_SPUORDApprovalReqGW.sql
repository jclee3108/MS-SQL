IF OBJECT_ID('KPXCM_SPUORDApprovalReqGW') IS NOT NULL 
    DROP PROC KPXCM_SPUORDApprovalReqGW
GO 

/************************************************************    
 ��  �� - ������-����ǰ�����ڰ���_KPXCM :     
 �ۼ��� - 20150705    
 �ۼ��� - �ڻ���    
 ������ - 20150727 �Ϻ��׸� ����(�����ڱ���, ������, ������, ��ջ�뷮)   
		- 20150731 ������ �Ǵ� 1���������� 0�� ��� �ܰ����� 0  
		- 20150804 ������ ���� ����, ���űݾ� ����(ǰ�� ��ȭ�ݾװ�)
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
           
    DECLARE @BaseCurrSeq INT
    SET @BaseCurrSeq = (SELECT TOP 1 EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 13) -- �ڱ���ȭ(KRW)
           
	/*=================================================================================================    
	=================================================================================================*/    
	  --1758,1759    
	SELECT @Date = ApproReqDate    
	FROM _TPUORDApprovalReq WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq    
	SELECT  @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,@Date),112)    
		   ,@DateFr = CONVERT(NCHAR(8),DATEADD(MM,-3,@Date),112)    
	    
	-- ���ǰ��    
	CREATE TABLE #GetInOutItem (        
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
	 CREATE TABLE #GetInOutStock (       
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
			 STDStockQty     DECIMAL(19,5) )   
	           
	 -- ���������    
	 CREATE TABLE #TLGInOutStock   (         
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
			 InOutDetailKind INT  )    
	    
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
    
	CREATE TABLE #ApprovalReqPrice(ApproReqSeq INT, CustSeq INT, ItemSeq INT, Price DECIMAL(19,5))
	INSERT INTO #ApprovalReqPrice
	SELECT A.ApproReqSeq, B.CustSeq, B.ItemSeq, 
		   CASE WHEN B.SMImpType = 8008004 -- ������
			    THEN (SELECT TOP 1 ISNULL(S.Price, 0)
						FROM _TUIImpDelvItem AS S
						LEFT OUTER JOIN _TUIImpDelv AS V WITH(NOLOCK) ON V.CompanySeq = S.CompanySeq
																	 AND V.DelvSeq = S.DelvSeq
					   WHERE S.CompanySeq = @CompanySeq
						 AND V.DelvDate = Q.DelvDate
						 AND S.ItemSeq = Q.ItemSeq
						 AND V.CustSeq = Q.CustSeq
					   ORDER BY S.DelvSeq DESC) -- ���� ���ϰŷ�ó�� �����԰�
				ELSE (SELECT TOP 1 ISNULL(T.Price, 0) AS Price 
						FROM _TPUDelvInItem AS T
						LEFT OUTER JOIN _TPUDelvIn AS U WITH(NOLOCK) ON U.CompanySeq = T.CompanySeq
																	AND U.DelvInSeq = T.DelvInSeq
					   WHERE T.CompanySeq = @CompanySeq
					     AND U.DelvInDate = L.DelvInDate
						 AND T.ItemSeq = L.ItemSeq
						 AND U.CustSeq = L.CustSeq
					   ORDER BY T.DelvInSeq DESC) -- ���� ���ϰŷ�ó�� �����԰�
		   END
	  FROM _TPUORDApprovalReq                  AS A WITH(NOLOCK)
	  LEFT OUTER JOIN _TPUORDApprovalReqItem   AS B WITH(NOLOCK) ON A.CompanySeq    = B.CompanySeq
                                                                AND A.ApproReqSeq   = B.ApproReqSeq
	  OUTER APPLY (SELECT X.CompanySeq,MAX(Z.DelvInDate) AS DelvInDate,Z.CustSeq,X.ItemSeq
                     FROM _TPUDelvIn       AS Z
                     JOIN _TPUDelvInItem   AS X WITH(NOLOCK) ON Z.CompanySeq = X.CompanySeq
                                                            AND Z.DelvInSeq  = X.DelvInSeq
                    WHERE Z.CompanySeq = @CompanySeq
                      AND Z.DelvInDate <= A.ApproReqDate
                      AND X.ItemSeq    = B.ItemSeq
                      AND Z.CustSeq    = B.CustSeq
                    GROUP BY X.CompanySeq,Z.CustSeq,X.ItemSeq) AS L     
	  OUTER APPLY (SELECT X.CompanySeq,MAX(Z.DelvDate) AS DelvDate,Z.CustSeq,X.ItemSeq
                     FROM _TUIImpDelv       AS Z
                     JOIN _TUIImpDelvItem   AS X WITH(NOLOCK) ON Z.CompanySeq = X.CompanySeq
                                                             AND Z.DelvSeq  = X.DelvSeq
                    WHERE Z.CompanySeq = @CompanySeq
                      AND Z.DelvDate <= A.ApproReqDate
                      AND X.ItemSeq    = B.ItemSeq
                      AND Z.CustSeq    = B.CustSeq
                    GROUP BY X.CompanySeq,Z.CustSeq,X.ItemSeq) AS Q
       WHERE A.CompanySeq    = @CompanySeq
         AND A.ApproReqSeq   = @ApproReqSeq
         
          
/*=================================================================================================    
=================================================================================================*/    
     SELECT ROW_NUMBER() OVER(ORDER BY A.ApproReqSeq) AS Num,   
            /*������*/    
             ISNULL(A.CompanySeq     , 0)       AS CompanySeq    
            ,ISNULL(A.ApproReqSeq    , 0)       AS ApproReqSeq    
            ,ISNULL(A.ApproReqNo     ,'')       AS ApproReqNo    
            ,ISNULL(A.ApproReqDate   ,'')       AS ApproReqDate    
            ,ISNULL(A.DeptSeq        , 0)       AS DeptSeq    
            ,ISNULL(C.DeptName       ,'')       AS DeptName    
            ,ISNULL(B.CurrSeq        , 0)       AS CurrSeq    
            ,ISNULL(D.CurrName       ,'')       AS CurrName    
            ,ISNULL(A.EmpSeq         , 0)       AS EmpSeq    
            ,ISNULL(E.EmpName        ,'')       AS EmpName    
            ,ISNULL(B.ExRate         , 0)       AS ExRate    
            ,ISNULL(J.TotDomAmt      , 0)       AS TotDomAmt    
            ,ISNULL(A.Remark         ,'')       AS Remark    
            ,ISNULL(B.UnitSeq        , 0)       AS UnitSeq    
            ,ISNULL(K.UnitName       ,'')       AS UnitName   
            ,ISNULL(B.SMImpType   , 0)   AS SMImpType -- �����ڱ����ڵ� -- 150730  
            ,ISNULL(P.MinorName   ,'')   AS SMImpTypeName -- �����ڱ��� -- 150730  
            /*������*/    
            ,ISNULL(B.CustSeq        , 0)       AS CustSeq    
            ,ISNULL(F.CustName       ,'')       AS CustName    
            ,ISNULL(B.MakerSeq       , 0)       AS MakerSeq    
            ,ISNULL(G.CustName       ,'')       AS MakerName    
            ,ISNULL(B.ItemSeq        , 0)       AS ItemSeq    
            ,ISNULL(H.ItemName       ,'')       AS ItemName    
            ,ISNULL(H.ItemNo         ,'')       AS ItemNo    
            ,ISNULL(H.Spec           ,'')       AS Spec    
            ,ISNULL(B.Memo1          ,'')       AS PurPose              --�뵵    
            ,ISNULL(B.Memo5          , 0)       AS PackingSeq            --���屸��    
            ,ISNULL(I.MinorName      ,'')       AS PackingName          --���屸��    
			,CASE WHEN ISNULL(B.CurrSeq,0) = @BaseCurrSeq 
				  THEN CONVERT(NVARCHAR(100),CONVERT(INT,ISNULL(L.Price,0))) 
				  ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(L.Price, 0))) 
				  END AS CurentPrice--������  -- 150730 -- �ڱ���ȭ(KRW) �ƴ� ��� �Ҽ���2�ڸ� ǥ�� 
            ,CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
				  THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(B.Memo7, 0)))
				  ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(B.Memo7, 0)))
				  END  AS FirstPrice           --1��������    
            ,CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
				  THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(B.Price, 0)))
				  ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(B.Price, 0)))
				  END       AS LastPrice            --������(�ܰ�) 
            ,(CASE WHEN ISNULL(L.Price,0) = 0 AND ISNULL(B.Memo7,0) = 0 -- 150731 �������� 1���������� 0�� ��� �ܰ����� 0  
				   THEN (CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
							  THEN '0.000'
							  ELSE '0' END)
				   ELSE (CASE WHEN ISNULL(L.Price, 0)=0  
							  THEN (CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
										 THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(B.Memo7, 0) - ISNULL(B.Price, 0)))
										 ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(B.Memo7, 0) - ISNULL(B.Price, 0)))
										 END)  
							  ELSE (CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
										 THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(L.Price, 0) - ISNULL(B.Price, 0)))
										 ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(L.Price, 0) - ISNULL(B.Price, 0)))
										 END)
							  END)  
				   END)             AS DiffPrice          --�ܰ�����        => ABS??? 
            ,CASE WHEN ISNULL(L.Price, 0)=0    
                  THEN 0    
                  ELSE ((CASE WHEN ISNULL(L.Price, 0)=0    
                              THEN ISNULL(B.Memo7, 0)    
                              ELSE ISNULL(L.Price, 0)    
                              END)-ISNULL(B.Price, 0))/ISNULL(L.Price, 0)    
                  END * 100                          AS TransRate          --������(%)  -- 150730  
            ,ISNULL(B.Qty            , 0)       AS Qty                --����    
            ,ISNULL(B.DelvDate       ,'')       AS DelvDate           --�����û��    
            --,ISNULL(J.TotCurAmt      , 0)       AS TotCurAmt          --���űݾ�    
            ,ISNULL(B.DomAmt,0) + ISNULL(B.DomVAT,0) AS TotCurAmt	   --���űݾ�
            ,ISNULL(N.OutQty         , 0)/3     AS OutQty             --��ջ�뷮  -- 150730  
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
  --LEFT OUTER JOIN (    
  --    SELECT X.CompanySeq,MAX(X.DelvInSeq) AS DelvInSeq,X.DelvInSerl,X.ItemSeq    
  --      FROM _TPUDelvIn       AS Z    
  --      JOIN _TPUDelvInItem   AS X WITH(NOLOCK)ON Z.CompanySeq = X.CompanySeq    
  --              AND Z.DelvInSeq  = X.DelvInSeq    
  --     WHERE Z.CompanySeq = @CompanySeq    
  --       AND Z.DelvInDate <= (SELECT ApproReqDate     FROM _TPUORDApprovalReq     WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)    
  --       AND X.ItemSeq    IN (SELECT DISTINCT ItemSeq FROM _TPUORDApprovalReqItem WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)      --��ȭ�������� ���߿� Ȯ���ϱ�    
  --     GROUP BY X.CompanySeq,X.DelvInSerl,X.ItemSeq    
  --   )                                   AS L             ON B.CompanySeq    = L.CompanySeq    
  --                AND B.ItemSeq       = L.ItemSeq     
  --LEFT OUTER JOIN _TPUDelvInItem                      AS M WITH(NOLOCK)ON L.CompanySeq    = M.CompanySeq    
  --                AND L.DelvInSeq     = M.DelvInSeq    
  --                AND L.DelvInSerl    = M.DelvInSerl 
	LEFT OUTER JOIN #ApprovalReqPrice      AS L WITH(NOLOCK) ON L.ApproReqSeq   = A.ApproReqSeq    
                     AND L.ItemSeq    = B.ItemSeq    
                     AND L.CustSeq    = B.CustSeq    
	LEFT OUTER JOIN #OutQty                             AS N WITH(NOLOCK)ON B.CompanySeq    = N.CompanySeq    
                  AND B.ItemSeq       = N.ItemSeq    
	LEFT OUTER JOIN #StockQty                           AS O WITH(NOLOCK)ON B.CompanySeq    = O.CompanySeq    
                  AND B.ItemSeq       = O.ItemSeq    
    LEFT OUTER JOIN _TDASMinor        AS P WITH(NOLOCK) ON P.CompanySeq   = B.CompanySeq    
                  AND P.MinorSeq   = B.SMImpType                                                           
                                                                    
      WHERE A.CompanySeq    = @CompanySeq    
        AND A.ApproReqSeq   = @ApproReqSeq    
    
    
  /*=================================================================================================    
=================================================================================================*/        
  RETURN  
  go 
  EXEC _SCOMGroupWarePrint 2, 1, 1, 1025093, 'ApprovalReq_CM', '106', ''