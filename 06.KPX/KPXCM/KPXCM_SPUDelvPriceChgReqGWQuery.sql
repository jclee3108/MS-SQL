IF OBJECT_ID('KPXCM_SPUDelvPriceChgReqGWQuery') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvPriceChgReqGWQuery
GO 
/*********************************************************************************************************************
 ��  �� - ���ų�ǰ�ܰ�������ο�û-�׷����
 �ۼ��� - 20150731
 �ۼ��� - ������
 ������ - 
 ********************************************************************************************************************/
CREATE PROC KPXCM_SPUDelvPriceChgReqGWQuery      
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,       
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
      
     DECLARE @docHandle      INT          ,    
			 @ChgReqSeq		 INT
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
   
	 SELECT @ChgReqSeq           = ISNULL(ChgReqSeq,0)
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )              
       WITH (ChgReqSeq           INT)      
        
	SELECT ROW_NUMBER() OVER( ORDER BY A.ChgReqSeq ) AS Num, 
	       BB.BizUnit		AS BizUnit   ,  
		   E.BizUnitName	AS BizUnitName  ,  
		   BB.CustSeq		AS CustSeq   ,
		   J.CustName		AS CustName,	-- ���Űŷ�ó  
		   B.DelvSeq		AS DelvSeq   ,  
		   B.DelvSerl		AS DelvSerl   ,  
		   D.ItemName		AS ItemName,	-- ǰ��
		   D.ItemNo			AS ItemNo   ,  
		   D.Spec			AS Spec    ,  
		   C.ItemSeq		AS ItemSeq   ,
		   C.Price			AS PriceOld,	-- �������ܰ�
		   B.Price			AS Price,		-- �����Ĵܰ�
		   ISNULL(C.Price,0) - ISNULL(B.Price,0) AS PriceGap, -- �ܰ����� 
		   C.CurAmt			AS CurAmtOld,	-- �������ݾ�
		   ISNULL(B.Price,0) * ISNULL(C.Qty,0)	AS CurAmt,	-- �����ıݾ�
		   ISNULL(C.CurAmt,0) - (ISNULL(B.Price,0) * ISNULL(C.Qty,0)) AS CurAmtGap,	-- �ݾ�����
		   C.UnitSeq,
		   N.UnitName
      FROM KPX_TPUDelvPriceChgReq				   AS A  
		 JOIN KPX_TPUDelvPriceChgReqItem	   AS B  WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
																 AND B.ChgReqSeq = A.ChgReqSeq
         LEFT OUTER JOIN _TPUDelvItem          AS C  WITH(NOLOCK) ON C.CompanySeq  = @CompanySeq  
                                                                 AND B.DelvSeq     = C.DelvSeq  
                                                                 AND B.DelvSerl    = C.DelvSerl  
         LEFT OUTER JOIN _TPUDelv              AS BB WITH(NOLOCK) ON C.CompanySeq  = BB.CompanySeq  
                                                                 AND B.DelvSeq     = BB.DelvSeq     
         LEFT OUTER JOIN _TDAItem              AS D  WITH(NOLOCK) ON D.CompanySeq  = @CompanySeq  
                                                                 AND C.ItemSeq     = D.ItemSeq  
         LEFT OUTER JOIN _TDABizUnit           AS E  WITH(NOLOCK) ON E.CompanySeq  = @CompanySeq  
                                                                 AND BB.BizUnit     = E.BizUnit  
         LEFT OUTER JOIN _TDACust              AS J  WITH(NOLOCK) ON J.CompanySeq  = @CompanySeq  
                                                                 AND BB.CustSeq     = J.CustSeq  
         LEFT OUTER JOIN _TDAUnit              AS N  WITH(NOLOCK) ON C.CompanySeq  = N.CompanySeq -- 20091223 �ڼҿ� ����     
                                                                 AND C.UnitSeq     = N.UnitSeq                                                                                           
   WHERE A.CompanySeq = @CompanySeq
     AND A.ChgReqSeq = @ChgReqSeq
   ORDER BY BB.DelvNo    
      
    RETURN      
    go 
    EXEC _SCOMGroupWarePrint 2, 1, 1, 1025966, 'DelvPrice_CM', '1', ''