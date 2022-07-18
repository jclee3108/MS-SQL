IF OBJECT_ID('KPXCM_SPUORDPOReqPrintQuery') IS NOT NULL 
    DROP PROC KPXCM_SPUORDPOReqPrintQuery
GO 

-- v2015.10.06 

-- ������� �߰� by����õ 
 /************************************************************
  ��  �� - ������-���ſ�û : ���ſ�û�����
  �ۼ��� - 20091209
  �ۼ��� - �̼���
  ������ - 20100331 UPDATEd BY �ڼҿ� :: ���ſ�û ���� �߰�
           20100331 UPDATEd BY �ڼҿ� :: MEMO1/2/3/4/5/6 �߰�
           20110610 UPDATED BY �輼ȣ :: MasterRamrk, Remark '<' '�� ���� Replace ó��
 ************************************************************/
  CREATE PROC KPXCM_SPUORDPOReqPrintQuery  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
   
 AS         
   CREATE TABLE #TPUORDPOReqItem (WorkingTag NCHAR(1) NULL)  
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPOReqItem'     
  IF @@ERROR <> 0 RETURN  
      --Query
     SELECT --Master
            Y.POReqSeq                                           , --���ſ�û�����ڵ�
            Y.POReqSerl                                          , --���ſ�û����
            X.POReqNo                                            , --���ſ�û��ȣ
            X.ReqDate                                            , --���ſ�û��
            LTRIM(RTRIM(ISNULL(A.DeptName,'')))  AS DeptName     , --��û�μ�
            LTRIM(RTRIM(ISNULL(B.EmpName,'')))   AS EmpName      , --��û�����
            REPLACE(LTRIM(RTRIM(ISNULL(X.Remark,''))),'<','��')    AS MasterRemark , --���(������)
            X.UMPOReqType                        AS UMPOReqType  , --���ſ�û���г����ڵ� 20100331 �ڼҿ� �߰�
            LTRIM(RTRIM(ISNULL(G.MinorName,''))) AS UMPOReqTypeName, --���ſ�û���� 20100331 �ڼҿ� �߰�
            
            --Detail
            LTRIM(RTRIM(ISNULL(H.PJTNo,'')))     AS PJTNo        , --������Ʈ��ȣ
            LTRIM(RTRIM(ISNULL(H.PJTName,'')))   AS PJTName      , --������Ʈ��
            LTRIM(RTRIM(ISNULL(C.ItemName,'')))  AS ItemName     , --ǰ��
            LTRIM(RTRIM(ISNULL(C.ItemNo,'')))    AS ItemNo       , --ǰ��
            LTRIM(RTRIM(ISNULL(C.Spec,'')))      AS Spec         , --�԰�
            LTRIM(RTRIM(ISNULL(D.UnitName,'')))  AS UnitName     , --����
            LTRIM(RTRIM(ISNULL(Y.DelvDate,'')))  AS DelvDate     , --�����û��
            ISNULL(Y.Qty,0)                      AS Qty          , --��û����
            LTRIM(RTRIM(ISNULL(E.CustName,''))) AS MakerName     , --Maker
            ISNULL(Y.Price,0)                    AS Price        , --�ܰ�
            CASE ISNULL(Y.CurAmt,0) WHEN 0 THEN Y.Price * Y.Qty ELSE Y.CurAmt END AS CurAmt  , --�ݾ�
            ISNULL(Y.CurVat,0)                   AS CurVat       , --�ΰ���
            LTRIM(RTRIM(ISNULL(F.CurrName,'')))  AS CurrName     , --��ȭ
            LTRIM(RTRIM(ISNULL(F.CurrUnit,'')))  AS CurrUnit     , --��ȭǥ��
            Y.ExRate                                             , --ȯ��
            REPLACE(LTRIM(RTRIM(ISNULL(Y.Remark,''))),'<','��') AS Remark,     --���(������)          
            ISNULL(H.PJTName,'')     AS PJTName  ,
            ISNULL(H.PJTNo,'')     AS PJTNo  ,
            ISNULL(Y.Memo1,'')                   AS Memo1        , -- 20100408 �ڼҿ� �߰�
            ISNULL(Y.Memo2,'')                   AS Memo2        , -- 20100408 �ڼҿ� �߰�
            ISNULL(Y.Memo3,'')                   AS Memo3        , -- 20100408 �ڼҿ� �߰�
            ISNULL(Y.Memo4,'')                   AS Memo4        , -- 20100408 �ڼҿ� �߰�
            ISNULL(Y.Memo5,'')                   AS Memo5        , -- 20100408 �ڼҿ� �߰�
            ISNULL(Y.Memo6,'')                   AS Memo6        , -- 20100408 �ڼҿ� �߰�
            (ROW_NUMBER() OVER(ORDER BY Y.POReqSerl)) AS Serl,      -- 20101020 ���ڰ��� ���� ��� ���� �߰� hkim
            I.MinorName AS Memo5Name 
       FROM #TPUORDPOReqItem                 AS Z    --����� �Է¹��� �� ����, �ϳ� �̻� �ǿ� ���ؼ� ��ȸ �����ϵ��� �ӽ����̺� ���
                       JOIN _TPUORDPOReq     AS X WITH(NOLOCK) ON X.CompanySeq   = @CompanySeq
                                                              AND X.POReqSeq     = Z.POReqSeq
                       JOIN _TPUORDPOReqItem AS Y WITH(NOLOCK) ON Y.CompanySeq   = X.CompanySeq
                                AND Y.POReqSeq     = X.POReqSeq 
            LEFT OUTER JOIN _TDADept         AS A WITH(NOLOCK) ON A.CompanySeq   = X.CompanySeq 
                                                              AND A.DeptSeq      = X.DeptSeq  
            LEFT OUTER JOIN _TDAEmp          AS B WITH(NOLOCK) ON B.CompanySeq   = X.CompanySeq 
                                                              AND B.EmpSeq       = X.EmpSeq  
            LEFT OUTER JOIN _TDAItem         AS C WITH(NOLOCK) ON C.CompanySeq   = Y.CompanySeq 
                                                              AND C.ItemSeq      = Y.ItemSeq  
            LEFT OUTER JOIN _TDAUnit         AS D WITH(NOLOCK) ON D.CompanySeq   = Y.CompanySeq 
                                                              AND D.UnitSeq      = Y.UnitSeq  
            LEFT OUTER JOIN _TDACust         AS E WITH(NOLOCK) ON E.CompanySeq   = Y.CompanySeq 
                                                              AND E.CustSeq      = Y.MakerSeq
            LEFT OUTER JOIN _TDACurr         AS F WITH(NOLOCK) ON F.CompanySeq   = Y.CompanySeq 
                                                              AND F.CurrSeq      = Y.CurrSeq
            LEFT OUTER JOIN _TDAUMinor       AS G WITH(NOLOCK) ON G.CompanySeq   = X.CompanySeq  -- 20100331 �ڼҿ� �߰�
                                                              AND G.MinorSeq     = X.UMPOReqType 
            LEFT OUTER JOIN _TPJTProject     AS H WITH(NOLOCK) ON X.Companyseq   = H.CompanySeq 
                                                              AND Y.PJTSeq       = H.PJTSeq 
            LEFT OUTER JOIN _TDAUMinor       AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = Y.Memo5 ) 
      WHERE X.CompanySeq = @CompanySeq
   ORDER BY Y.POReqSeq, Y.POReqSerl
  
 RETURN  
  go 
  begin tran 
  
  EXEC _SCOMGroupWarePrint 2, 1, 1, 1026397, 'BizTrip_CM', '1', ''
  
  rollback 