IF OBJECT_ID('KPXCM_VQCProcResult_POP') IS NOT NULL
    DROP VIEW KPXCM_VQCProcResult_POP
GO 

-- v2016.05.12 

CREATE VIEW KPXCM_VQCProcResult_POP
AS
    

         SELECT  B.CompanySeq                           AS CompanySeq           --�����ڵ�
                ,ROw_Number() OVER(PARTITION BY B.SourceSeq,B.SourceSerl ORDER BY B.CompanySeq,B.QCSeq,B.QCSerl)        AS IDX
----------------��õ������------------------------------------------------------------------------------------------------
                ,B.SourceSeq                            AS WorkOrderSeq         --��õ�ڵ�D
                ,B.SourceSerl                           AS WorkOrderSerl        --��õ����D
----------------��õ����,��������-----------------------------------------------------------------------------------------
                ,B.SMSourceType                         AS SMSourceType         --��õ�����ڵ�
                ,J.MinorName                            AS SMSourceTypeName     --��õ���и�
                ,CASE WHEN ISNULL(A.QCType,0)=0 
                           THEN ISNULL(B.QCType,0)
                           ELSE ISNULL(A.QCType,0)
                 END                                    AS QCType               --�˻�����ڵ�(Union)
                ,CASE WHEN ISNULL(A.QCType,0)=0                                 
                           THEN ISNULL(K.QCTypeName,'')
                           ELSE ISNULL(E.QCTypeName,'')
                 END                                    AS QCTypeName           --�˻������(Union)
----------------�˻絥����------------------------------------------------------------------------------------------------
                ,A.QCSeq                                AS QCSeq                --�˻��ڵ�
                ,B.QCSerl                               AS QCSerl               --�˻����
                ,A.QCNo                                 AS QCNo                 --�˻��ȣ
                ,A.ItemSeq                              AS ItemSeq              --ǰ���ڵ�M
                ,M.ItemName                             AS ItemName             --ǰ��M
                ,M.ItemNo                               AS ItemNo               --ǰ��M
                ,A.LotNo                                AS LotNo                --LotNo
                ,A.SMTestResult                         AS SMTestResultM         --�˻����ڵ�(Master)
                ,C.MinorName                            AS SMTestResultMName     --�˻���(Master)
                ,A.IsEnd                                AS IsEnd                --�ϷῩ��
                ,A.WorkCenterSeq                        AS WorkCenterSeq        --��ũ����
                ,A.OKQty                                AS OKQty                --�հݼ���
                ,A.BadQty                               AS BadQty               --�ҷ�����
                ,B.TestItemSeq                          AS TestItemSeq          --�˻��׸��ڵ�
                ,F.TestItemName                         AS TestItemName         --�˻��׸񳻺��ڵ�
                ,F.OutTestItemName                      AS OutTestItemName      --�˻��׸��(��ܿ�)
                ,F.InTestItemName                       AS InTestItemName       --�˻��׸��(�系��)
                ,B.QAAnalysisType                       AS QAAnalysisType       --�м�����ڵ�
                ,D.QAAnalysisTypeName                   AS QAAnalysisTypeName   --�м������
                ,B.QCUnit                               AS QCUnit               --�˻�����ڵ�
                ,H.QCUnitName                           AS QCUnitName           --�˻������
                ,B.TestValue                            AS TestValue            --����ġ
                ,B.SMTestResult                         AS SMTestResultD         --��/�������ڵ�(Detail)
                ,I.MinorName                            AS SMTestResultDName     --��/��������(Detail)
                ,B.IsSpecial                            AS IsSpecial            --Ưäó��
                ,B.TestHour                             AS TestHour             --�ҿ�ð�
                ,B.Remark                               AS Remark               --�׸�Ư������
                ,B.TestDate                             AS TestDate             --�˻�����
                ,CONVERT(NCHAR(8),B.RegDate,112)        AS RegDate              --�˻��������
                ,CONVERT(NCHAR(5),B.RegDate,108)        AS RegTime              --�˻����ð�
                ,CONVERT(NCHAR(8),B.LastDateTime,112)   AS LastDate             --����������
                ,B.UMTestGroup                          AS UMTestGroup          --�˻�׷��ڵ�(Detail)
                ,L.MinorName                            AS UMTestGroupName      --�˻�׷��(Detail)
                ,B.EmpSeq                               AS EmpSeq               --������ڵ�(Detail)
                ,N.EmpName                              AS EmpName              --����ڸ�(Detail)
                ,B.RegEmpSeq                            AS RegEmpSeq            --������ڵ�(Detail)
                ,O.EmpName                              AS RegEmpName           --����ڸ�(Detail)
                ,Q.EmpSeq                               AS LastEmpSeq           --�����������ڵ�
                ,Q.EmpName                              AS LastEmpName          --���������ڸ�
----------------�Ƿڵ�����------------------------------------------------------------------------------------------------
                ,A.ReqSeq                               AS ReqSeq               --�Ƿ��ڵ�M
                ,A.ReqSerl                              AS ReqSerl              --�Ƿڼ���M
                ,S.BizUnit                              AS ReqBizUnit              --�Ƿڻ���ι��ڵ�
                ,Y.BizUnitName                          AS ReqBizUnitName          --�Ƿڻ���ι���
                ,S.ReqDate                              AS ReqDate              --�Ƿ�����
                ,S.ReqNo                                AS ReqNo                --�Ƿڹ�ȣ
                ,S.DeptSeq                              AS ReqDeptSeq              --�Ƿںμ��ڵ�
                ,Z.DeptName                             AS ReqDeptName             --�Ƿںμ���
                ,S.EmpSeq                               AS ReqEmpSeq               --�Ƿڴ�����ڵ�
                ,A1.EmpName                             AS ReqEmpName              --�Ƿڴ���ڸ�
                ,S.CustSeq                              AS ReqCustSeq              --�Ƿڰ����ڵ�
                ,B1.CustName                            AS ReqCustName             --�Ƿڰ�����
                ,R.LotNo                                AS ReqLotNo                --�Ƿ�LotNo
                ,R.WHSeq                                AS ReqWHSeq                --�Ƿ�â���ڵ�
                ,T.WHName                               AS ReqWHName               --�Ƿ�â���
                ,R.UnitSeq                              AS ReqUnitSeq              --�Ƿڴ����ڵ�
                ,U.UnitName                             AS ReqUnitName             --�Ƿڴ�����
                ,R.ReqQty                               AS ReqReqQty               --�Ƿڼ���
                ,R.Remark                               AS ReqRemark               --�Ƿں��
                ,R.PreItemSeq                           AS ReqPreItemSeq           --������ǰ�ڵ�
                ,X.ItemName                             AS ReqPreItemName          --������ǰ��
                ,R.CleanYN                              AS ReqCleanYN              --��������
                ,R.Memo1                                AS ReqMemo1                --�޸�1
                ,R.AfterWeight                          AS ReqAfterWeight          --�����Ĺ���
                ,R.BeforWeight                          AS ReqBeforWeight          --��������
                ,R.StockWeight                          AS ReqStockWeight          --���繫��
                ,R.ProcGubunSeq                         AS ReqProcGubunSeq         --���������ڵ�
                ,V.MinorName                            AS ReqProcGubunName        --�������и�
                ,R.CustInReqTime                        AS ReqCustInReqTime        --��ü�԰��û�ð�
                ,R.UpCarTemp                            AS ReqUpCarTemp            --�����µ�
                ,R.CarSeq                               AS ReqCarSeq               --�����ڵ�
                ,W.CarNo                                AS ReqCarNo                --������ȣ
                ,W.Driver                               AS ReqDriver               --�������
                ,W.TelNo1                               AS ReqTelNo1               --����ó
                ,CAST(C1.LowerLimit AS NVARCHAR(MAX))   AS LowerLimit              --����ġ
                ,CAST(C1.UpperLimit AS NVARCHAR(MAX))   AS UpperLimit              --����ġ
                ----,C1.LowerLimit                          AS LowerLimit              --����ġ
                ----,C1.UpperLimit                          AS UpperLimit              --����ġ
           FROM KPX_TQCTestResult                   AS A WITH(NOLOCK)
LEFT OUTER JOIN KPX_TQCTestResultItem               AS B WITH(NOLOCK)ON A.CompanySeq        = B.CompanySeq
                                                                    AND A.QCSeq             = B.QCSeq
LEFT OUTER JOIN _TDAUMinor                          AS C WITH(NOLOCK)ON A.CompanySeq        = C.CompanySeq
                                                                    AND A.SMTestResult      = C.MinorSeq
LEFT OUTER JOIN KPX_TQCQAAnalysisType               AS D WITH(NOLOCK)ON B.CompanySeq        = D.CompanySeq
                                                                    AND B.QAAnalysisType    = D.QAAnalysisType
LEFT OUTER JOIN KPX_TQCQAProcessQCType              AS E WITH(NOLOCK)ON A.CompanySeq        = E.CompanySeq     
                                                                    AND A.QCType            = E.QCType
LEFT OUTER JOIN KPX_TQCQATestItems                  AS F WITH(NOLOCK)ON B.CompanySeq        = F.CompanySeq
                                                                    AND B.TestItemSeq       = F.TestItemSeq
LEFT OUTER JOIN KPX_TQCQAAnalysisType               AS G WITH(NOLOCK)ON B.CompanySeq        = G.CompanySeq
                                                                    AND B.QAAnalysisType    = G.QAAnalysisType
LEFT OUTER JOIN KPX_TQCQAProcessQCUnit              AS H WITH(NOLOCK)ON B.CompanySeq        = H.CompanySeq
                                                                    AND B.QCUnit            = H.QCUnit
LEFT OUTER JOIN _TDASMinor                          AS I WITH(NOLOCK)ON B.CompanySeq        = I.CompanySeq
                                                                    AND B.SMTestResult      = I.MinorSeq
LEFT OUTER JOIN _TDASMinor                          AS J WITH(NOLOCK)ON B.CompanySeq        = J.CompanySeq
                                                                    AND B.SMSourceType      = J.MinorSeq
LEFT OUTER JOIN KPX_TQCQAProcessQCType              AS K WITH(NOLOCK)ON B.COmpanySeq        = K.CompanySeq
                                                                    AND B.QCType            = K.QCType
LEFT OUTER JOIN _TDAUMinor                          AS L WITH(NOLOCK)ON B.CompanySeq        = L.CompanySeq
                                                                    AND B.UMTestGroup       = L.MinorSeq
LEFT OUTER JOIN _TDAItem                            AS M WITH(NOLOCK)ON A.CompanySeq        = M.CompanySeq
                                                                    AND A.ItemSeq           = M.ItemSeq
LEFT OUTER JOIN _TDAEmp                             AS N WITH(NOLOCK)ON B.CompanySeq        = N.CompanySeq
                                                                    AND B.EmpSeq            = N.EmpSeq
LEFT OUTER JOIN _TDAEmp                             AS O WITH(NOLOCK)ON B.CompanySeq        = O.CompanySeq
                                                                    AND B.RegEmpSeq         = O.EmpSeq
LEFT OUTER JOIN _TCAUser                            AS P WITH(NOLOCK)ON B.CompanySeq        = P.CompanySeq
                                                                    AND B.LastUserSeq       = P.UserSeq
LEFT OUTER JOIN _TDAEmp                             AS Q WITH(NOLOCK)ON P.CompanySeq        = Q.CompanySeq
                                                                    AND P.EmpSeq            = Q.EmpSeq
LEFT OUTER JOIN KPX_TQCTestRequestItem              AS R WITH(NOLOCK)ON A.CompanySeq        = R.CompanySeq
                                                                    AND A.ReqSeq            = R.ReqSeq
                                                                    AND A.ReqSerl           = R.ReqSerl
LEFT OUTER JOIN KPX_TQCTestRequest                  AS S WITH(NOLOCK)ON R.CompanySeq        = S.CompanySeq
                                                                    AND R.ReqSeq            = S.ReqSeq
LEFT OUTER JOIN _TDAWH                              AS T WITH(NOLOCK)ON R.CompanySeq        = T.CompanySeq
                                                                    AND R.WHSeq             = T.WHSeq
LEFT OUTER JOIN _TDAUnit                            AS U WITH(NOLOCK)ON R.CompanySeq        = U.CompanySeq
                                                                    AND R.UnitSeq           = U.UnitSeq
LEFT OUTER JOIN _TDAUMinor                          AS V WITH(NOLOCK)ON R.CompanySeq        = V.CompanySeq
                                                                    AND R.ProcGubunSeq      = V.MinorSeq
LEFT OUTER JOIN _TLGCar                             AS W WITH(NOLOCK)ON R.CompanySeq        = W.CompanySeq
                                                                    AND R.CarSeq            = W.CarSeq
LEFT OUTER JOIN _TDAItem                            AS X WITH(NOLOCK)ON R.CompanySeq        = X.CompanySeq
                                                                    AND R.PreItemSeq        = X.ItemSeq
LEFT OUTER JOIN _TDABizUnit                         AS Y WITH(NOLOCK)ON S.CompanySeq        = Y.CompanySeq
                                                                    AND S.BizUnit           = Y.BizUnit
LEFT OUTER JOIN _TDADept                            AS Z WITH(NOLOCK)ON S.CompanySeq        = Z.CompanySeq
                                                                    AND S.DeptSeq           = Z.DeptSeq
LEFT OUTER JOIN _TDAEmp                             AS A1 WITH(NOLOCK)ON S.CompanySeq       = A1.CompanySeq
                                                                     AND S.EmpSeq           = A1.EmpSeq
LEFT OUTER JOIN _TDACust                            AS B1 WITH(NOLOCK)ON S.CompanySeq       = B1.CompanySeq
                                                                     AND S.CustSeq          = B1.CustSeq
LEFT OUTER JOIN KPX_TQCQASpec                       AS C1 WITH(NOLOCK)ON C1.CompanySeq      = B.CompanySeq
                                                                     AND C1.QCType          = B.QCType
                                                                     AND C1.QAAnalysisType  = B.QAAnalysisType
                                                                     AND C1.TestItemSeq     = B.TestItemSeq
                                                                     AND C1.QCUnit          = B.QCUnit
                                                                     AND C1.ItemSeq         = A.ItemSeq
                                                                     AND S.ReqDate          BETWEEN C1.SDate AND C1.EDate 
          WHERE  A.CompanySeq     = 2
            --AND B.SMSourceType NOT IN (1000522004,1000522008)
            --AND (CASE WHEN A.ItemSeq = R.ItemSeq THEN '1' ELSE '99999999999' END) <>'1'
       --ORDER BY  B.SMSourceType                     --��õ�����ڵ�
                --,(CASE WHEN ISNULL(A.QCType,0)=0 
                --           THEN ISNULL(B.QCType,0)
                --           ELSE ISNULL(A.QCType,0)
                -- END)                                --�˻�����ڵ�(Union)

/*
------ǰ��˻�԰����̺� (�Ʒ�)
------LEFT OUTER JOIN KPX_TQCQASpec                       AS T WITH(NOLOCK)ON T.CompanySeq        = B.CompanySeq
------                                                                    AND T.QCType            = B.QCType
------                                                                    AND T.TestItemSeq       = B.TestItemSeq
------                                                                    AND T.QAAnalysisType    = B.QAAnalysisType
------                                                                    AND T.QCUnit            = B.QCUnit
------                                                                    AND T.ItemSeq           = A.ItemSeq
*/
GO


