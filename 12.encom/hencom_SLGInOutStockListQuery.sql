IF OBJECT_ID('hencom_SLGInOutStockListQuery') IS NOT NULL 
    DROP PROC hencom_SLGInOutStockListQuery
GO 

-- v2017.04.04
/************************************************************    
  ��  �� - ������-���Һ���ȸ : ��ȸ    
  ǰ���ڻ�з��� �������� ǰ���� �������,��� ��ȸ�Ѵ�.    
      
  �ۼ��� - 20160629    
  �ۼ��� - �ڼ���    
 ************************************************************/    
        
 CREATE PROC dbo.hencom_SLGInOutStockListQuery                    
     @xmlDocument    NVARCHAR(MAX) ,                
     @xmlFlags       INT  = 0,                
     @ServiceSeq     INT  = 0,                
     @WorkingTag     NVARCHAR(10)= '',                      
     @CompanySeq     INT  = 1,                
     @LanguageSeq    INT  = 1,                
     @UserSeq        INT  = 0,                
     @PgmSeq         INT  = 0             
         
 AS            
      
     DECLARE @docHandle    INT,    
             @ItemName     NVARCHAR(200) ,    
             @DeptSeq      INT ,    
             @DateTo       NCHAR(8) ,    
             @DateFr       NCHAR(8)      
   EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
     
     SELECT  @ItemName     = ISNULL(ItemName, ''),    
             @DeptSeq      = ISNULL(DeptSeq , 0),    
             @DateTo       = ISNULL(DateTo  , ''),    
             @DateFr       = ISNULL(DateFr  , '')   
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
    WITH (   ItemName   NVARCHAR(200), 
             DeptSeq    INT ,    
             DateTo     NCHAR(8) ,    
             DateFr     NCHAR(8) )    
 /*0������ ���� ��� ó��*/              
     SET ANSI_WARNINGS OFF              
     SET ARITHIGNORE ON              
     SET ARITHABORT OFF        
          
     CREATE TABLE #TMPItem( ItemSeq INT)    
     
     INSERT #TMPItem( ItemSeq )    
     SELECT A.ItemSeq    
     FROM _TDAItem AS A WITH(NOLOCK)  
     LEFT OUTER JOIN _TDAItemAsset AS AI WITH(NOLOCK) ON AI.CompanySeq = @CompanySeq   
                                                     AND AI.AssetSeq = A.AssetSeq    
     WHERE A.CompanySeq = @CompanySeq    
     AND AI.AssetSeq = 6 --������    
     AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)    
     AND (@ItemName = '' OR A.ItemName LIKE @ItemName + '%')    
     
 -- ���ǰ��                           
      CREATE TABLE #GetInOutItem                          
      (                           
          ItemSeq INT,                           
          ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- ǰ��Һз�                          
          ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- ǰ���ߺз�                          
          ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- ǰ���з�                          
      )                          
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
          InOutType       INT,                            
          InOutSeq        INT,                            
          InOutSerl       INT,                            
          DataKind        INT,                            
          InOutSubSerl    INT,                    
          InOut           INT,                            
          InOutDate       NCHAR(8),                            
          WHSeq           INT,                            
            FunctionWHSeq   INT,                            
          ItemSeq         INT,                            
          UnitSeq         INT,                            
          Qty             DECIMAL(19,5),                             
          StdQty          DECIMAL(19,5),                          
          InOutKind       INT,                          
          InOutDetailKind INT                           
 )                            
  ------------------------------------------------------------------------                
    --�����ȸ ���� �߰�                        
      DECLARE  @BizUnit            INT                                 
              ,@FactUnit           INT                        
              ,@WHSeq              INT                        
              ,@SMWHKind           INT                        
              ,@CustSeq            INT                        
              ,@IsTrustCust        NCHAR(1)                         
              ,@IsSubDisplay       NCHAR(1)                         
              ,@IsUnitQry          NCHAR(1)                         
              ,@QryType            NCHAR(1)                         
              ,@IsSetItem          NCHAR(1)                         
              ,@SMABC              INT                        
              ,@MngDeptSeq         INT                        
              ,@IsUseDetail        NCHAR(1)                         
                  
     SELECT    @BizUnit        =    ISNULL(@BizUnit       , 1)                                          
             , @FactUnit       =    ISNULL(@FactUnit      , 0)                          
             , @WHSeq          =    ISNULL(@WHSeq         , 0)                         
             , @SMWHKind       =    ISNULL(@SMWHKind      , 0)              
             , @CustSeq        =    ISNULL(@CustSeq       , 0)                         
             , @IsTrustCust    =    ISNULL(@IsTrustCust   , '0')                         
             , @IsSubDisplay   =    ISNULL(@IsSubDisplay  , '0')                         
             , @IsUnitQry      =    ISNULL(@IsUnitQry     , '0')                         
             , @QryType        =    ISNULL(@QryType       , 'S')                        
             , @IsSetItem      =    ISNULL(@IsSetItem     , '0')                    
             , @SMABC          =    ISNULL(@SMABC         , 0)                        
             , @MngDeptSeq     =    ISNULL(@MngDeptSeq     ,0)                          
             , @IsUseDetail    =    ISNULL(@IsUseDetail    ,'0')                   
            
     
   -- �����ȸ ���ǰ�� ���                           
      INSERT INTO #GetInOutItem                          
      (                           
          ItemSeq,                           
          ItemClassSSeq, ItemClassSName, -- ǰ��Һз�                          
          ItemClassMSeq, ItemClassMName, -- ǰ���ߺз�                          
          ItemClassLSeq, ItemClassLName  -- ǰ���з�                          
      )                          
      SELECT DISTINCT A.ItemSeq,                          
              C.MinorSeq AS ItemClassSSeq, C.MinorName AS ItemClassSName, -- 'ǰ��Һз�'                           
              E.MinorSeq AS ItemClassMSeq, E.MinorName AS ItemClassMName, -- 'ǰ���ߺз�'                           
              G.MinorSeq AS ItemClassLSeq, G.MinorName AS ItemClassLName  -- 'ǰ���з�'                           
        FROM #TMPItem AS MST                        
        JOIN _TDAItem                     AS A WITH (NOLOCK) ON A.ItemSeq = MST.ItemSeq  
        JOIN _TDAItemSales                AS H WITH (NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.ItemSeq = H.ItemSeq                           
        JOIN _TDAItemAsset                AS I WITH (NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.AssetSeq = I.AssetSeq -- ǰ���ڻ�з�                           
                                  
        -- �Һз�                           
          LEFT OUTER JOIN _TDAItemClass     AS B WITH(NOLOCK) ON ( A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) AND A.CompanySeq = B.CompanySeq )                          
        LEFT OUTER JOIN _TDAUMinor  AS C WITH(NOLOCK) ON ( B.UMItemClass = C.MinorSeq AND B.CompanySeq = C.CompanySeq AND C.IsUse = '1' )                          
        LEFT  OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( C.MinorSeq = D.MinorSeq AND D.Serl in (1001,2001) AND C.MajorSeq = D.MajorSeq AND C.CompanySeq = D.CompanySeq )                          
        -- �ߺз�                           
          LEFT OUTER JOIN  _TDAUMinor  AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq AND E.IsUse = '1' )                          
        LEFT OUTER JOIN _TDAUMinorValue AS F WITH(NOLOCK) ON ( E.MinorSeq = F.MinorSeq AND F.Serl = 2001 AND E.MajorSeq = F.MajorSeq AND E.CompanySeq = F.CompanySeq )                          
        -- ��з�                           
        LEFT OUTER JOIN _TDAUMinor  AS G WITH(NOLOCK) ON ( F.ValueSeq = G.MinorSeq AND F.CompanySeq = G.CompanySeq AND G.IsUse = '1' )                          
                            
       WHERE A.CompanySeq = @CompanySeq                             
           AND ( @QryType <> 'B' OR (@QryType = 'B' AND H.IsSet <> '1') )                           
         AND ( @IsSetItem <> '1' OR (H.IsSet = @IsSetItem) )                              
         AND I.IsQty <> '1' -- ������ ����                           
         AND ( @SMABC  = 0  OR A.SMABC = @SMABC )                  
         
    ------------------------------------------------------------------------                
                      
   -- â����� ��������                          
     EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq,   -- �����ڵ�                          
                             @BizUnit      = @BizUnit,      --  ����ι�                          
                             @FactUnit     = @FactUnit, -- ��������                            
                             @DateFr       = @DateFr,       -- ��ȸ�ⰣFr                          
                             @DateTo       = @DateTo,       -- ��ȸ�ⰣTo                          
                             @WHSeq        = @WHSeq,             -- â������   -- ����â��                          
                             @SMWHKind     = @SMWHKind,     -- â����                           
                             @CustSeq      = @CustSeq,      -- ��Ź�ŷ�ó                          
                             @IsTrustCust  = @IsTrustCust,  -- ��Ź����                          
                             @IsSubDisplay = @IsSubDisplay, -- ���â�� ��ȸ                          
                             @IsUnitQry    = @IsUnitQry,    -- ������ ��ȸ                           
                             @QryType      = @QryType,      -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������                          
                             @MngDeptSeq   = @MngDeptSeq,                          
                             @IsUseDetail  = '1'             
            
--  select '#GetInOutStock',* from #GetInOutStock          
--  select '#TLGInOutStock',* from #TLGInOutStock          
--  return    
  ----------------------------------------------          
  DECLARE @QryTypeSeq INT,          
           @MonthQry   NCHAR(1),          
           @PrevDate   NCHAR(8),          
           @FromDate   NCHAR(8),          
           @FromYM     NCHAR(6),          
           @PrevYM     NCHAR(6),          
           @ToYM       NCHAR(6),          
           @WHMajor    NCHAR(1)          
                         
      DECLARE @PreStkDate NVARCHAR(8)          
         
      SELECT @PreStkDate = B.FrSttlYM+'01'          
      FROM _TCOMEnv   AS A WITH(NOLOCK)            
      JOIN _TDAAccFiscal AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq and A.EnvValue between B.FrSttlYM and B.ToSttlYM )          
     WHERE A.CompanySeq = @CompanySeq           
       AND A.EnvSeq = 1006          
               
       IF @@ROWCOUNT = 0 SELECT @PreStkDate = ''          
     SELECT @DateFr = CASE WHEN @PreStkDate > @DateFr THEN @PreStkDate ELSE @DateFr END         
              
                 
       SELECT @PrevDate = LEFT(@FromYM,4) + '0101'          
            
      IF LEN(@DateFr) = 6          
      SELECT @FromDate = LTRIM(RTRIM(@DateFr)) + '01'          
      ELSE          
      SELECT @FromDate = @DateFr          
                  
      EXEC _SACGetAccTerm @CompanySeq, @FromDate, @FromYM OUTPUT ,@ToYM OUTPUT          
            
     SELECT @PrevYM   = CONVERT(NCHAR(6), DATEADD(M, -1, @FromDate), 112)          
    

    CREATE TABLE #GetInOutStock_Temp          
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
           ,StkYMD NCHAR(8)          
       )          
         
     IF LEFT(LTRIM(RTRIM(@DateFr)),6) = @FromYM         
         OR LEFT(LTRIM(RTRIM(@DateFr)),6) = LEFT(@PreStkDate,6) -- ��ȸ����-���۳���� �������۳���� ���ϴ� ȸ��Ⱓ�� ���۳���� ������ ������� ���̿����� ��ȸ �ϱ�         
     BEGIN          
       
         INSERT INTO #GetInOutStock_Temp(WHSeq,FunctionWHSeq,ItemSeq,UnitSeq,PrevQty,InQty,OutQty,StockQty,STDPrevQty,STDInQty,STDOutQty,STDStockQty,StkYMD)          
         SELECT A.WHSeq, A.FunctionWHSeq, A.ItemSeq, A.UnitSeq,          
             SUM(ISNULL(PrevQty,0)) AS PrevQty,          
             0 AS InQty,          
             0 AS OutQty,          
             0 AS StockQty,          
             SUM(ISNULL(STDPrevQty,0)) AS STDPrevQty,          
             0 AS STDInQty,          
             0 AS STDOutQty,          
             0 AS STDStockQty,        
             A.StkYM+'01'          
         FROM _TLGWHStock  AS A WITH (NOLOCK)          
                         JOIN #GetInOutItem AS I ON A.ItemSeq = I.ItemSeq         
         WHERE  A.CompanySeq  = @CompanySeq          
         And  A.StkYM = @FromYM          
         GROUP BY A.WHSeq, A.FunctionWHSeq, A.ItemSeq, A.UnitSeq , A.StkYM         
     END        
     ELSE         
       BEGIN        
        INSERT INTO #GetInOutStock_Temp(WHSeq,FunctionWHSeq,ItemSeq,UnitSeq,PrevQty,InQty,OutQty,StockQty,STDPrevQty,STDInQty,STDOutQty,STDStockQty,StkYMD)            
                   SELECT A.WHSeq, A.FunctionWHSeq, A.ItemSeq, A.UnitSeq,            
                          SUM(A.PrevQty + A.InQty - A.OutQty) AS PrevQty,            
                          0 AS InQty,            
                          0 AS OutQty,            
                          0 AS StockQty,            
                          SUM(A.STDPrevQty + A.STDInQty - A.STDOutQty) AS STDPrevQty,            
                          0 AS STDInQty,            
                          0 AS STDOutQty,            
                          0 AS STDStockQty,          
                          A.StkYM+'01'          
                     FROM _TLGWHStock  AS A WITH (NOLOCK)            
                                      JOIN #GetInOutItem AS I ON A.ItemSeq = I.ItemSeq            
                    WHERE  A.CompanySeq  = @CompanySeq            
                      And  A.StkYM BETWEEN @FromYM AND @PrevYM            
                    GROUP BY A.WHSeq, A.FunctionWHSeq, A.ItemSeq, A.UnitSeq  ,A.StkYM          
                      
         
     END         
    
    
     INSERT INTO #GetInOutStock_Temp(WHSeq,FunctionWHSeq,ItemSeq,UnitSeq,PrevQty,InQty,OutQty,StockQty,STDPrevQty,STDInQty,STDOutQty,STDStockQty,StkYMD)            
     SELECT A.WHSeq, A.FunctionWHSeq, A.ItemSeq, A.UnitSeq,          
               SUM(A.InOut * A.Qty) AS PrevQty,          
             0 AS InQty,          
             0 AS OutQty,          
             0 AS StockQty,          
             SUM(A.InOut * A.STDQty) AS STDPrevQty,          
             0 AS STDInQty,          
             0 AS STDOutQty,          
             0 AS STDStockQty,     
             A.InOutDate          
     FROM #TLGInOutStock AS A          
     WHERE  A.InOutDate  >= LEFT(@DateFr,6) + '01'            
     And  A.InOutDate  < @DateTo          
     GROUP BY A.WHSeq, A.FunctionWHSeq, A.ItemSeq, A.UnitSeq,A.InOutDate          
            
        
      SELECT  A.StkYMD,           
              A.ItemSeq,          
              SUM(ISNULL(A.PrevQty,0)) AS PrevQty          
      INTO #TMPPrevStock          
        FROM #GetInOutStock_Temp AS A           
      JOIN #GetInOutItem AS B ON B.ItemSeq = A.ItemSeq          
      GROUP BY A.StkYMD,A.ItemSeq          
                
                 
     CREATE TABLE #TMPInOutData    
     (    
         InOutDate   NCHAR(8),    
         ItemSeq     INT ,    
         InQty       DECIMAL(19,5),    
         OutQty      DECIMAL(19,5),    
         InOut       INT,    
         InAmt       DECIMAL(19,5),    
         OutAmt      DECIMAL(19,5) ,  
         EtcInQty       INT,   
         EtcOutQty      DECIMAL(19,5),  
         EtcInAmt       DECIMAL(19,5),    
         EtcOutAmt      DECIMAL(19,5)    
             
             
     )    
       
--     delete from #TLGInOutStock where itemseq <> 4081
--  select * from _TESMGInOutStock where itemseq = 4081
  
--select 123, * from #TLGInOutStock   
--     return  
 --�԰����� ����    
     INSERT #TMPInOutData(InOutDate,ItemSeq,InQty,InOut)    
     SELECT  InOutDate,          
             ItemSeq,          
             SUM(ISNULL(Qty,0)) AS Qty ,          
             1 AS InOut --�԰����          
     FROM #TLGInOutStock          
     WHERE InOut =1          
     AND InOutType NOT IN (30,40)--��Ÿ�԰�,�������  
     GROUP BY InOutDate,ItemSeq          
     
 --������� ����    
     INSERT #TMPInOutData(InOutDate,ItemSeq,OutQty,InOut)    
     SELECT  InOutDate,          
             ItemSeq,          
             SUM(ISNULL(Qty,0)) AS Qty ,          
             -1 AS InOut --������          
     FROM #TLGInOutStock          
     WHERE InOut = -1       
     AND InOutType NOT IN (30,40)--��Ÿ�԰�,�������     
     GROUP BY InOutDate,ItemSeq      
     
  
  
 --��Ÿ�԰� ����    
     INSERT #TMPInOutData(InOutDate,ItemSeq,EtcInQty,InOut)    
     SELECT  InOutDate,          
             ItemSeq,          
             SUM(ISNULL(Qty,0)) AS Qty ,          
             1 AS InOut --�԰����          
     FROM #TLGInOutStock          
     WHERE InOut =1          
     AND InOutType = 40--��Ÿ�԰�  
     GROUP BY InOutDate,ItemSeq          
     
 --��Ÿ��� ����    
     INSERT #TMPInOutData(InOutDate,ItemSeq,EtcOutQty,InOut)    
     SELECT  InOutDate,          
             ItemSeq,          
             SUM(ISNULL(Qty,0)) AS Qty ,          
             -1 AS InOut --������          
     FROM #TLGInOutStock          
     WHERE InOut = -1       
     AND InOutType = 30 --��Ÿ���  
     GROUP BY InOutDate,ItemSeq   
       
--     select * from #TMPInOutData return  
         
 --�ݾ�: �Ϻ�����ܰ����ó���Ǿ�� ��ȸ��.    
     CREATE TABLE #TMPStkAmt (ItemSeq INT, InOutType INT, InOutDate NCHAR(8),Amt DECIMAL(19,5), InOut INT)    
     INSERT #TMPStkAmt (ItemSeq , InOutType , InOutDate ,Amt , InOut )    
     SELECT ItemSeq , InOutType, InOutDate,Amt ,InOut    
     FROM _TESMGInOutStock  WITH(NOLOCK)   
     WHERE CompanySeq = @CompanySeq    
     AND ItemSeq IN (SELECT ItemSeq FROM #TMPItem )    
     AND InOutDate BETWEEN @DateFr AND @DateTo    
	 --�߰� 2017.03.06 by free�ڼ��� 
	--AND CostKeySeq IN (SELECT CostKeySeq 
	--		FROM _TESMDCostKey 
	--		WHERE CompanySeq = @CompanySeq 
	--		AND CostYM BETWEEN LEFT(@DateFr,6) AND LEFT(@DateTo ,6)

				 --AND SMCostMng = 5512004 AND PlanYear = '' ) --�⺻����
--         SELECT ItemSeq FROM #TMPItem where itemseq = 4081 return 
--         select * from _TESMGInOutStock where itemseq = 4081
--            select '#TMPStkAmt', * from #TMPStkAmt return  
--            
 --�԰�ݾ�    
     INSERT #TMPInOutData(InOutDate,ItemSeq,InAmt,InOut)    
     SELECT InOutDate ,ItemSeq,SUM(ISNULL(Amt,0)) , 1     
     FRom #TMPStkAmt    
     WHERE InOut = 1          
     AND InOutType NOT IN (30,40)--��Ÿ�԰�,�������  
     GROUP BY InOutDate,ItemSeq     
         
 --���ݾ�    
     INSERT #TMPInOutData(InOutDate,ItemSeq,OutAmt,InOut)    
     SELECT InOutDate ,ItemSeq,SUM(ISNULL(Amt,0)) , -1     
     FRom #TMPStkAmt    
       WHERE InOut = -1             
       AND InOutType NOT IN (30,40)--��Ÿ�԰�,�������    
     GROUP BY InOutDate,ItemSeq     
--��Ÿ���  
     INSERT #TMPInOutData(InOutDate,ItemSeq,EtcOutAmt,InOut)    
     SELECT InOutDate ,ItemSeq,SUM(ISNULL(Amt,0)) , -1     
     FRom #TMPStkAmt    
     WHERE InOutType = 30 --��Ÿ���  
     GROUP BY InOutDate,ItemSeq     
--��Ÿ�԰�  
     INSERT #TMPInOutData(InOutDate,ItemSeq,EtcInAmt,InOut)    
     SELECT InOutDate ,ItemSeq,SUM(ISNULL(Amt,0)) , 1     
     FRom #TMPStkAmt    
     WHERE InOutType = 40 --��Ÿ�԰�  
     GROUP BY InOutDate,ItemSeq     
       
--  select * from #TMPInOutData  
--  return  
    
    
     SELECT  A.ItemSeq,    
             I.ItemName,    
             I.ItemNo,    
             I.DeptSeq,    
             T.DeptName,    
             D.InOutDate,    
             CONVERT(DECIMAL(19,5),ISNULL(D.InQty,0)) AS InQty,    
             CONVERT(DECIMAL(19,5),ISNULL(D.OutQty,0)) AS OutQty,    
             CONVERT(DECIMAL(19,5),(SELECT SUM(ISNULL(PrevQty,0)) AS PrevQty
                                      FROM #TMPPrevStock          
                                      WHERE ItemSeq = A.ItemSeq AND StkYMD < D.InOutDate           
                                      )) AS PrevStockQty, --�������(�̿�����)      
             
             CONVERT(DECIMAL(19,5),ISNULL((SELECT SUM(ISNULL(PrevQty,0))            
                                             FROM #TMPPrevStock          
                                             WHERE ItemSeq = A.ItemSeq AND StkYMD < D.InOutDate           
                                             ),0) + ISNULL(D.InQty,0)+ ISNULL(D.EtcInQty,0)  - ISNULL(D.OutQty,0)- ISNULL(D.EtcOutQty,0)) AS StockQty, --��������    
             CONVERT(DECIMAL(19,0),ISNULL(D.InAmt,0)) AS InAmt,    
             CONVERT(DECIMAL(19,0),ISNULL(D.OutAmt,0)) AS OutAmt,    
             CONVERT(DECIMAL(19,5),ISNULL(D.EtcInQty,0)) AS EtcInQty,    
             CONVERT(DECIMAL(19,5),ISNULL(D.EtcOutQty,0)) AS EtcOutQty,    
             CONVERT(DECIMAL(19,0),ISNULL(D.EtcInAmt,0)) AS EtcInAmt,    
             CONVERT(DECIMAL(19,0),ISNULL(D.EtcOutAmt,0)) AS EtcOutAmt,    
--             ----------
             (SELECT MAX(CalcDate) FROM _TESMCProdStkDailyPrice WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq AND CalcDate < D.InOutDate) AS PrevDate,
             CONVERT(DECIMAL(19,0),(SELECT MAX(Price) FROM _TESMCProdStkDailyPrice WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq AND CalcDate = D.InOutDate)) AS Price
            ,TA.DispSeq 
     INTO #TMPRstQry
     FROM #TMPItem AS A        
     LEFT OUTER JOIN _TDAItem AS I  WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq        
     LEFT OUTER JOIN _TDADept AS T  WITH(NOLOCK) ON T.CompanySeq = @CompanySeq AND T.DeptSeq = I.DeptSeq    
     LEFT OUTER JOIN hencom_TDADeptAdd AS TA WITH(NOLOCK) ON TA.DeptSeq = I.DeptSeq     
     LEFT OUTER JOIN(SELECT InOutDate,    
                            ItemSeq,    
                            SUM(ISNULL(InQty,0)) AS InQty,    
                            SUM(ISNULL(OutQty ,0)) AS OutQty,    
                            SUM(ISNULL(InAmt,0)) AS InAmt,    
                            SUM(ISNULL(OutAmt ,0)) AS OutAmt,    
                            SUM(ISNULL(EtcInQty,0)) AS EtcInQty,  --��Ÿ�԰����  
                            SUM(ISNULL(EtcOutQty ,0)) AS EtcOutQty,  --��Ÿ������  
                            SUM(ISNULL(EtcInAmt,0)) AS EtcInAmt,  --��Ÿ�԰�ݾ�  
                            SUM(ISNULL(EtcOutAmt ,0)) AS EtcOutAmt  --��Ÿ���ݾ�  
                            FROM #TMPInOutData    
                            GROuP BY InOutDate,ItemSeq
                    ) AS D ON D.ItemSeq = A.ItemSeq    
    WHERE D.InOutDate BETWEEN @DateFr AND @DateTo    
    ORDER BY D.InOutDate,A.ItemSeq,TA.DispSeq 
   

   SELECT DeptSeq, ItemSeq, MIN(InOutDate) AS InOutDate 
     INTO #MinInOutDate 
     FROM #TMPRstQry 
    GROUP BY DeptSeq, ItemSeq
    
    SELECT A.DeptSeq, 
           A.ItemSeq, 
           ISNULL(A.PrevStockQty,0) AS PrevStockQty, --�������(�̿�����)      
           ISNULL(ISNULL(A.PrevStockQty,0) * (SELECT CONVERT(DECIMAL(19,0),MAX(Price)) FROM _TESMCProdStkDailyPrice WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq AND CalcDate = A.PrevDate),0) AS PrevStockAmt--�������ݾ�
      INTO #PreData 
      FROM #TMPRstQry AS A 
      JOIN #MinInOutDate AS B ON ( B.DeptSeq = A.DeptSeq AND B.ItemSeq = A.ItemSeq AND B.InOutDate = A.InOutDate ) 


    SELECT A.ItemSeq,    
           A.ItemName,    
           A.ItemNo,    
           A.DeptSeq,    
           A.DeptName,    
           SUM(ISNULL(A.InQty,0)) AS InQty,    
           SUM(ISNULL(A.OutQty,0)) AS OutQty,     
           MAX(ISNULL(B.PrevStockQty,0)) AS PrevStockQty, --�������(�̿�����)      
           MAX(ISNULL(B.PrevStockQty,0)) + SUM(ISNULL(A.InQty,0)) - SUM(ISNULL(A.OutQty,0)) AS StockQty, --��������    
           SUM(ISNULL(A.InAmt,0)) AS InAmt ,    
           SUM(ISNULL(A.OutAmt ,0)) AS OutAmt,  
           ROUND(SUM(ISNULL(A.OutAmt,0)) / SUM(NULLIF(A.OutQty,0)),0) AS OutPrice, -- ���ܰ� 
           SUM(ISNULL(A.EtcInQty,0)) AS EtcInQty,  --���԰����
           SUM(ISNULL(A.EtcOutQty,0)) AS EtcOutQty,   --��������
           SUM(ISNULL(A.EtcInAmt,0)) AS EtcInAmt, --���԰�ݾ� 
           SUM(ISNULL(A.EtcOutAmt,0)) AS EtcOutAmt,   --�����ݾ�
           --             ----------
           ROUND(SUM(ISNULL(A.InAmt,0)) / NULLIF(SUM(ISNULL(A.InQty,0)),0),0) AS InPrice, --�����԰�ܰ�
           MAX(ISNULL(B.PrevStockAmt,0)) AS PrevStockAmt, --�������ݾ�
           SUM(ROUND(ISNULL(StockQty * Price,0),0)) AS StockAmt, --�����ݾ�
           ROUND(SUM(ROUND(ISNULL(StockQty * Price,0),0)) / NULLIF(SUM(ISNULL(A.StockQty,0)),0),0) AS Price  --���ϱ��شܰ�(���ܰ�)
          ,2 AS Sort
      INTO #SS1 
      FROM #TMPRstQry           AS A 
      LEFT OUTER JOIN #PreData  AS B ON ( B.DeptSeq = A.DeptSeq AND B.ItemSeq = A.ItemSeq ) 
     GROUP BY A.ItemSeq, A.ItemName, A.ItemNo, A.DeptSeq, A.DeptName
     
    UNION ALL 

    SELECT 
           0 AS ItemSeq,    
           '' AS ItemName,    
           '' AS ItemNo,    
           0 AS DeptSeq,    
           'TOTAL' AS DeptName,    
           SUM(ISNULL(A.InQty,0)) AS InQty,    
           SUM(ISNULL(A.OutQty,0)) AS OutQty,     
           0 AS PrevStockQty, --�������(�̿�����)      
           0 AS StockQty, --��������    
           SUM(ISNULL(A.InAmt,0)) AS InAmt ,    
           SUM(ISNULL(A.OutAmt ,0)) AS OutAmt,  
           ROUND(SUM(ISNULL(A.OutAmt,0)) / SUM(NULLIF(A.OutQty,0)),0) AS OutPrice, -- ���ܰ� 
           SUM(ISNULL(A.EtcInQty,0)) AS EtcInQty,  --���԰����
           SUM(ISNULL(A.EtcOutQty,0)) AS EtcOutQty,   --��������
           SUM(ISNULL(A.EtcInAmt,0)) AS EtcInAmt, --���԰�ݾ� 
           SUM(ISNULL(A.EtcOutAmt,0)) AS EtcOutAmt,   --�����ݾ�
           --             ----------
           ROUND(SUM(ISNULL(A.InAmt,0)) / NULLIF(SUM(ISNULL(A.InQty,0)),0),0) AS InPrice, --�����԰�ܰ�
           0 AS PrevStockAmt, --�������ݾ�
           SUM(ROUND(ISNULL(StockQty * Price,0),0)) AS StockAmt, --�����ݾ�
           ROUND(SUM(ROUND(ISNULL(StockQty * Price,0),0)) / NULLIF(SUM(ISNULL(A.StockQty,0)),0),0) AS Price  --���ϱ��شܰ�(���ܰ�)
          ,1 AS Sort 
    FROM #TMPRstQry AS A
    
    SELECT *, @DateFr AS DateFr, @DateTo AS DateTo
      FROM #SS1 
     WHERE (@WorkingTag = '' OR ( @WorkingTag = 'P' AND Sort = 2 ))
     ORDER BY Sort, DeptName, ItemName
    
    SELECT 
        ItemSeq,    
        ItemName,    
        ItemNo,    
        DeptSeq,    
        DeptName,    
        InOutDate,    
        ISNULL(InQty,0) AS InQty,    
        ISNULL(OutQty,0) AS OutQty,     
        ISNULL(PrevStockQty,0) AS PrevStockQty, --�������(�̿�����)      
        ISNULL(StockQty,0) AS StockQty, --��������    
        ISNULL(InAmt,0) AS InAmt ,    
        ISNULL(OutAmt ,0) AS OutAmt,  
        ROUND(ISNULL(A.OutAmt,0) / NULLIF(A.OutQty,0),0) AS OutPrice, -- ���ܰ� 
        ISNULL(EtcInQty,0) AS EtcInQty,  --���԰����
        ISNULL(EtcOutQty,0) AS EtcOutQty,   --��������
        ISNULL(EtcInAmt,0) AS EtcInAmt, --���԰�ݾ� 
        ISNULL(EtcOutAmt,0) AS EtcOutAmt,   --�����ݾ�
        --             ----------
        ROUND(ISNULL(InAmt / InQty,0),0) AS InPrice ,--�����԰�ܰ�
        ROUND(ISNULL(PrevStockQty * (SELECT MAX(Price) FROM _TESMCProdStkDailyPrice WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq AND CalcDate = A.PrevDate),0),0) AS PrevStockAmt,--�������ݾ�
        ROUND(ISNULL(StockQty * Price,0),0) AS StockAmt, --�����ݾ�
        ISNULL(Price,0) AS Price  --���ϱ��شܰ�(���ܰ�)
        ,2 AS Sort 
    INTO #SS2 
    FROM #TMPRstQry AS A
    
    UNION ALL 

    SELECT 
           0 AS ItemSeq,    
           '' AS ItemName,    
           '' AS ItemNo,    
           0 AS DeptSeq,    
           'TOTAL' AS DeptName,    
           '' AS InOutDate,    
           SUM(ISNULL(A.InQty,0)) AS InQty,    
           SUM(ISNULL(A.OutQty,0)) AS OutQty,     
           0 AS PrevStockQty, --�������(�̿�����)      
           0 AS StockQty, --��������    
           SUM(ISNULL(A.InAmt,0)) AS InAmt ,    
           SUM(ISNULL(A.OutAmt ,0)) AS OutAmt,  
           ROUND(SUM(ISNULL(A.OutAmt,0)) / SUM(NULLIF(A.OutQty,0)),0) AS OutPrice, -- ���ܰ� 
           SUM(ISNULL(A.EtcInQty,0)) AS EtcInQty,  --���԰����
           SUM(ISNULL(A.EtcOutQty,0)) AS EtcOutQty,   --��������
           SUM(ISNULL(A.EtcInAmt,0)) AS EtcInAmt, --���԰�ݾ� 
           SUM(ISNULL(A.EtcOutAmt,0)) AS EtcOutAmt,   --�����ݾ�
           --             ----------
           ROUND(SUM(ISNULL(A.InAmt,0)) / NULLIF(SUM(ISNULL(A.InQty,0)),0),0) AS InPrice, --�����԰�ܰ�
           0 AS PrevStockAmt, --�������ݾ�
           SUM(ROUND(ISNULL(StockQty * Price,0),0)) AS StockAmt, --�����ݾ�
           ROUND(SUM(ROUND(ISNULL(StockQty * Price,0),0)) / NULLIF(SUM(ISNULL(A.StockQty,0)),0),0) AS Price  --���ϱ��شܰ�(���ܰ�)
          ,1 AS Sort 
    FROM #TMPRstQry AS A

    SELECT * 
      FROM #SS2 
     ORDER BY Sort, DeptName, InOutDate, ItemName
    
 RETURN
 