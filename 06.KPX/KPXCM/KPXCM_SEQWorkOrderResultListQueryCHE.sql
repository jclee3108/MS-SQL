
IF OBJECT_ID('KPXCM_SEQWorkOrderResultListQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkOrderResultListQueryCHE
GO 

-- v2015.07.23 
/************************************************************    
��  �� - ������-�۾�������ȸ : ��ȸ    
�ۼ��� - 20110519    
�ۼ��� - �����    
************************************************************/    
CREATE PROC KPXCM_SEQWorkOrderResultListQueryCHE
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT             = 0,    
    @ServiceSeq     INT             = 0,    
    @WorkingTag     NVARCHAR(10)    = '',    
    @CompanySeq     INT             = 1,    
    @LanguageSeq    INT             = 1,    
    @UserSeq        INT             = 0,    
    @PgmSeq         INT             = 0    
AS    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle          INT,    
            @QryFrDate          NCHAR(8) ,    
            @QryToDate          NCHAR(8) ,    
            @QryAccUnitSeq      INT ,    
            @QryWorkOperSerl    INT ,    
            @QryProgType        INT ,
            @WorkOperSeq        INT ,
            @QryWkDiv           INT ,
            @EmpSeq             INT ,
            @DeptClassSeq       INT , 
            @WONo               INT , 
            @ReqEmpName         NVARCHAR(100), 
            @ProtectLevel       INT , 
            @PreProtect         INT , 
            @WorkReason         INT , 
            @ProtectKind        INT , 
            @ToolName           NVARCHAR(100), 
            @ToolNo             NVARCHAR(100), 
            @ToolKindName       NVARCHAR(100) 


    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
      
    SELECT @QryFrDate           = ISNULL(QryFrDate,''),    
           @QryToDate           = ISNULL(QryToDate,''),    
           @QryAccUnitSeq       = ISNULL(QryAccUnitSeq,0),    
           @QryWorkOperSerl     = ISNULL(QryWorkOperSerl,0),    
           @QryProgType         = ISNULL(QryProgType,0),
           @WorkOperSeq         = ISNULL(WorkOperSeq,0),
           @QryWkDiv            = ISNULL(QryWkDiv, 0),
           @EmpSeq              = ISNULL(EmpSeq, 0),
           @DeptClassSeq        = ISNULL(DeptClassSeq,0), 
           @WONo                = ISNULL(WONo          ,''),
           @ReqEmpName          = ISNULL(ReqEmpName       ,''),
           @ProtectLevel        = ISNULL(ProtectLevel  ,0),
           @PreProtect          = ISNULL(PreProtect    ,0),
           @WorkReason          = ISNULL(WorkReason    ,0),
           @ProtectKind         = ISNULL(ProtectKind   ,0),
           @ToolName            = ISNULL(ToolName      ,''),
           @ToolNo              = ISNULL(ToolNo        ,''),
           @ToolKindName        = ISNULL(ToolKindName  ,'')
    
        FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
        WITH (
                QryFrDate          NCHAR(8) ,    
                QryToDate          NCHAR(8) ,    
                QryAccUnitSeq      INT ,    
                QryWorkOperSerl    INT ,    
                QryProgType        INT ,
                WorkOperSeq        INT ,
                QryWkDiv           INT ,
                EmpSeq             INT ,
                DeptClassSeq       INT , 
                WONo               INT , 
                ReqEmpName          NVARCHAR(100), 
                ProtectLevel       INT , 
                PreProtect         INT , 
                WorkReason         INT , 
                ProtectKind        INT , 
                ToolName           NVARCHAR(100), 
                ToolNo             NVARCHAR(100), 
                ToolKindName       NVARCHAR(100) 
             )
    
    IF @QryWkDiv = 6028004    
    BEGIN    
        SELECT @QryWkDiv = 20104001    
    END    
    ELSE IF @QryWkDiv = 6028005    
    BEGIN    
        SELECT @QryWkDiv = 20104005    
    END    
    
    SELECT DISTINCT  A.WorkType        ,
           E.FactUnitName  AS PdAccUnitName        ,     
           C.PdAccUnitSeq  AS PdAccUnitSeq         ,     
           F.ToolNo        AS ToolNo               ,     
           F.ToolName      AS  ToolName            ,     
           C.ToolSeq       AS  ToolSeq             ,     
               
           G.SectionCode   AS SectionCode          ,     
           C.SectionSeq    AS  SectionSeq          ,     
           H.CCtrName      AS ActCenterName        ,     
           F1.MngValSeq    AS CCtrSeq              ,     
           I2.MinorName    AS ProgTypeName         ,     
           C2.MinorName    AS WorkOperName         ,  
               
           C.ProgType      AS ProgType             ,     
           J.DeptName      AS ReqDeptName          ,     
           D.DeptSeq       AS ReqDeptSeq           ,     
           K.EmpName       AS ReqEmpName           ,     
           D.EmpSeq        AS ReqEmpSeq            ,     
           D.WorkName                              ,    
           D.ReqDate       AS ReqDate              ,     
           D.WONo          AS WONo                 ,     
           D.ReqCloseDate  AS ReqCloseDate         ,     
           A.WorkContents  AS WorkContents         ,     
           I1.MinorName    AS WorkOperSerlName     ,     
               
           B.WorkOperSerl  AS WorkOperSerl         ,    
           B.WOReqSeq      AS WOReqSeq             ,    
           B.WOReqSerl     AS WOReqSerl            ,    
           B.ReceiptSeq    AS ReceiptSeq           ,
           A.DeptClassSeq                ,
           W4.MinorName    AS DeptClassName        ,
           CASE WHEN W1.ValueText = '1' THEN 'FrmEQWorkOrderActRltCHE_KPXCM'
                WHEN W2.ValueText = '1' THEN 'FrmEQSWorkOrderActRltCHE'
                WHEN W3.ValueText = '1' THEN 'FrmEQPreventRepairRltRegCHE'END AS JumpPgmId, -- 111214 �߰� by õ���
           I.Remark, 
           I.ProtectKind, 
           M.MinorName AS ProtectKindName, 
           I.WorkReason, 
           N.Minorname AS WorkReasonName, 
           I.PreProtect, 
           R.MinorName AS PreProtectName, 
           O.MngValText AS ToolKindName,  -- ���񱸺� 
           Q.MinorName AS ProtectLevelName, -- ���������
           P.MngValSeq AS ProtectLevel
           
      FROM  _TEQWorkOrderReceiptMasterCHE             AS A     
              JOIN _TEQWorkOrderReceiptItemCHE          AS B ON 1 = 1 AND A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq    
              JOIN _TEQWorkOrderReqItemCHE              AS C ON 1 = 1 AND B.CompanySeq = C.CompanySeq AND B.WOReqSeq = C.WOReqSeq AND B.WOReqSerl = C.WOReqSerl    
      LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE         AS D ON 1 = 1 AND C.CompanySeq = D.CompanySeq AND B.WOReqSeq = D.WOReqSeq
      LEFT OUTER JOIN _TDAFactUnit                      AS E ON 1 = 1 AND C.CompanySeq = E.CompanySeq AND C.PdAccUnitSeq = E.FactUnit    
      LEFT OUTER JOIN _TPDTool                          AS F ON 1 = 1 AND C.CompanySeq = F.CompanySeq AND C.ToolSeq = F.ToolSeq    
      LEFT OUTER JOIN _TPDToolUserDefine                 AS F1 ON 1 = 1 AND F.CompanySeq = F1.CompanySeq AND F.ToolSeq = F1.ToolSeq AND F1.MngSerl = 1000005    
      LEFT OUTER JOIN _TPDSectionCodeCHE                AS G ON 1 = 1 AND C.CompanySeq = G.CompanySeq AND C.SectionSeq = G.SectionSeq    
      LEFT OUTER JOIN _TDACCtr                          AS H ON 1 = 1 AND F1.CompanySeq = H.CompanySeq AND F1.MngValSeq = H.CCtrSeq    
      LEFT OUTER JOIN _TDAUMinor                        AS I1 ON 1 = 1 AND B.CompanySeq = I1.CompanySeq AND B.WorkOperSerl = I1.MinorSeq    
      LEFT OUTER JOIN _TDAUMinor                        AS I2 ON 1 = 1 AND C.CompanySeq = I2.CompanySeq AND C.ProgType = I2.MinorSeq    
      LEFT OUTER JOIN _TDADept                          AS J ON 1 = 1 AND D.CompanySeq = J.CompanySeq AND D.DeptSeq = J.DeptSeq    
      LEFT OUTER JOIN _TDAEmp                           AS K ON 1 = 1 AND D.CompanySeq = K.CompanySeq AND D.EmpSeq = K.EmpSeq    
      LEFT OUTER JOIN _TDAUMinor                        AS C2 ON 1 = 1 AND C.CompanySeq = C2.CompanySeq AND C.WorkOperSeq = C2.MinorSeq
      LEFT OUTER JOIN _TDAUMinorValue                   AS W1 ON 1 = 1 AND A.CompanySeq = W1.CompanySeq AND A.WorkType = W1.MinorSeq AND W1.MinorSeq = 20104005 AND W1.Serl = 1000001 -- �Ϲ��۾�
      LEFT OUTER JOIN _TDAUMinorValue                   AS W2 ON 1 = 1 AND A.CompanySeq = W2.CompanySeq AND A.WorkType = W2.MinorSeq AND W2.MinorSeq IN (20104001, 20104002) AND W2.Serl = 1000002 -- �ڻ�ȭ/Ư��
      LEFT OUTER JOIN _TDAUMinorValue                   AS W3 ON 1 = 1 AND A.CompanySeq = W3.CompanySeq AND A.WorkType = W3.MinorSeq AND W3.MinorSeq = 20104004 AND W3.Serl = 1000001 -- ��������
      LEFT OUTER JOIN (
                        SELECT ReceiptSeq, EmpSeq 
                          FROM _TEQWorkRealResultCHE 
                         WHERE CompanySeq = @CompanySeq AND DivSeq = 20117001 AND EmpSeq = @EmpSeq
                      ) AS L ON A.ReceiptSeq = L.ReceiptSeq 
      LEFT OUTER JOIN _TDAUMinor                        AS W4  ON 1 = 1 AND A.CompanySeq    = W4.CompanySeq  AND A.DeptClassSeq  = W4.MinorSeq      
      LEFT OUTER JOIN KPXCM_TEQWorkOrderActRltToolInfo  AS I ON ( I.CompanySeq = @CompanySeq AND I.ReceiptSeq = B.ReceiptSeq AND I.WOReqSeq = B.WOReqSeq AND I.WOReqSerl = B.WOReqSerl ) 
      LEFT OUTER JOIN _TDAUMinor                        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = I.ProtectKind ) 
      LEFT OUTER JOIN _TDAUMinor                        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = I.WorkReason ) 
      LEFT OUTER JOIN _TDAUMinor                        AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = I.PreProtect ) 
      LEFT OUTER JOIN _TPDToolUserDefine                 AS O ON ( O.CompanySeq = @CompanySeq AND O.ToolSeq = C.ToolSeq AND O.MngSerl = 1000001 )
      LEFT OUTER JOIN _TPDToolUserDefine                 AS P ON ( P.CompanySeq = @CompanySeq AND P.ToolSeq = C.ToolSeq AND P.MngSerl = 1000002 )
      LEFT OUTER JOIN _TDAUMinor                        AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = P.MngValSeq ) 
      
     WHERE 1 = 1    
       AND (A.CompanySeq    = @CompanySeq)    
       AND (A.ActRltDate    BETWEEN @QryFrDate AND @QryToDate)              
       AND (C.PdAccUnitSeq  = @QryAccUnitSeq  OR  @QryAccUnitSeq = 0 )    
       AND (B.WorkOperSerl  = @QryWorkOperSerl OR @QryWorkOperSerl =0)    
       AND (C.ProgType      = @QryProgType OR @QryProgType=0)  
       AND (C.WorkOperSeq   = @WorkOperSeq OR @WorkOperSeq=0)     
       AND (A.WorkType  = @QryWkDiv OR @QryWkDiv = 0)    
       AND (L.EmpSeq  = @EmpSeq OR @EmpSeq = 0)
       AND (A.DeptClassSeq  = @DeptClassSeq OR @DeptClassSeq = 0) 
       AND (@WONo = '' OR D.WONo = @WONo) 
       AND (@ReqEmpName = '' OR K.EmpName LIKE @ReqEmpName + '%') 
       AND (@ProtectLevel = 0 OR P.MngValSeq = @ProtectLevel)
       AND (@PreProtect = 0 OR I.PreProtect = @PreProtect) 
       AND (@WorkReason = 0 OR I.WorkReason = @WorkReason) 
       AND (@ProtectKind = 0 OR I.ProtectKind = @ProtectKind) 
       AND (@ToolName = '' OR F.ToolName LIKE @ToolName + '%') 
       AND (@ToolNo = '' OR F.ToolNo LIKE @ToolNo + '%') 
       AND (@ToolKindName = '' OR O.MngValText LIKE @ToolKindName + '%') 
    
    /*
      UNION ALL
     
      SELECT A.WorkType        ,
              E.FactUnitName  AS PdAccUnitName        ,     
              C.FactUnit  AS PdAccUnitSeq         ,     
              F.ToolNo        AS ToolNo               ,     
              F.ToolName      AS  ToolName            ,     
              C.ToolSeq       AS  ToolSeq             ,     
                  
              G.SectionCode   AS SectionCode          ,     
              C.SectionSeq    AS  SectionSeq          ,     
              H.CCtrName      AS ActCenterName        ,     
              F1.MngValSeq    AS CCtrSeq              ,     
              '' AS ProgTypeName,
              C2.MinorName    AS WorkOperName         ,  
                  
              0 AS ProgType,
              '' AS ReqDeptName,
              0 AS ReqDeptSeq,
              '' AS ReqEmpName,
              0 AS ReqEmpSeq,
              '' WorkName,    
              A.ReceiptDate       AS ReqDate              ,     
              B.WorkOrderNo          AS WONo                 ,     
              '' AS ReqCloseDate,
              CASE WHEN A.WorkType = 20104004 THEN A.RltContents END  AS WorkContents         ,     
              I1.MinorName    AS WorkOperSerlName     ,     
                  
              0  AS WorkOperSerl         ,    
              B.WOReqSeq      AS WOReqSeq             ,    
              0 AS WOReqSerl,
              A.ReceiptSeq    AS ReceiptSeq           ,
              A.DeptClassSeq                          ,
              W4.MinorName    AS DeptClassName        ,            
              CASE WHEN W1.ValueText = '1' THEN 'FrmEQWorkOrderActRltCHE'
                   WHEN W2.ValueText = '1' THEN 'FrmEQSWorkOrderActRltCHE' 
                   WHEN W3.ValueText = '1' THEN 'FrmEQPreventRepairRltRegCHE'END AS JumpPgmId -- 111214 �߰� by õ���
   FROM _TEQPreventRepairRltMasterCHE              AS A    
    LEFT JOIN _TEQPreventRepairWorkOrderCHE     AS B  ON A.CompanySeq = B.CompanySeq    
                         AND A.WOReqSeq = B.WOReqSeq
    LEFT OUTER JOIN _TEQPreventRepairRltItemCHE AS C   ON 1 = 1 
                                                                     AND A.CompanySeq = C.CompanySeq 
                                                                     AND A.ReceiptSeq = C.ReceiptSeq  
    LEFT OUTER JOIN _TDAFactUnit                  AS E   ON 1 = 1 
                                                                     AND A.CompanySeq = E.CompanySeq 
                                                                     AND C.FactUnit = E.FactUnit    
    LEFT OUTER JOIN _TPDTool                      AS F   ON 1 = 1 
                                                                     AND A.CompanySeq = F.CompanySeq 
                                                                     AND C.ToolSeq = F.ToolSeq    
    LEFT OUTER JOIN _TPDToolUserDefine            AS F1  ON 1 = 1 
                                                                     AND F.CompanySeq = F1.CompanySeq 
                                                                     AND F.ToolSeq = F1.ToolSeq 
                                                                     AND F1.MngSerl = 1000005    
    LEFT OUTER JOIN _TPDSectionCodeCHE          AS G   ON 1 = 1 
                                                                     AND A.CompanySeq = G.CompanySeq 
                                                                     AND C.SectionSeq = G.SectionSeq    
    LEFT OUTER JOIN _TDACCtr                      AS H   ON 1 = 1 
                                                                     AND F1.CompanySeq = H.CompanySeq 
                                                                     AND F1.MngValSeq = H.CCtrSeq    
    LEFT OUTER JOIN _TDAUMinor     AS I1  ON 1 = 1 
                                                                     AND B.CompanySeq = I1.CompanySeq 
  AND A.WorkOperSerl = I1.MinorSeq    
    LEFT OUTER JOIN _TDAUMinor                    AS C2  ON 1 = 1 AND A.CompanySeq = C2.CompanySeq AND A.WorkOperSeq = C2.MinorSeq
    LEFT OUTER JOIN _TDAUMinorValue               AS W1  ON 1 = 1 AND A.CompanySeq = W1.CompanySeq AND A.WorkType = W1.MinorSeq AND W1.MinorSeq = 20104005 AND W1.Serl = 1000001 -- �Ϲ��۾�
    LEFT OUTER JOIN _TDAUMinorValue               AS W2  ON 1 = 1 AND A.CompanySeq = W2.CompanySeq AND A.WorkType = W2.MinorSeq AND W2.MinorSeq IN (20104001, 20104002) AND W2.Serl = 1000002 -- �ڻ�ȭ/Ư��
    LEFT OUTER JOIN _TDAUMinorValue               AS W3  ON 1 = 1 AND A.CompanySeq = W3.CompanySeq AND A.WorkType = W3.MinorSeq AND W3.MinorSeq = 20104004 AND W3.Serl = 1000001 -- ��������
          LEFT OUTER JOIN (SELECT ReceiptSeq, DivSeq 
                             FROM _TEQPreventRepairRealResultCHE 
                            WHERE CompanySeq = @CompanySeq 
                              AND DivType = 20117001 
                              AND DivSeq = @EmpSeq) AS L ON A.ReceiptSeq = L.ReceiptSeq
          LEFT OUTER JOIN _TDAUMinor AS W4  ON 1 = 1  
                                                        AND A.CompanySeq    = W4.CompanySeq  
                                                        AND A.DeptClassSeq  = W4.MinorSeq    
   WHERE (A.CompanySeq    = @CompanySeq)               
         AND (A.ReceiptDate   BETWEEN @QryFrDate AND @QryToDate)     
         AND (A.WorkType      = @QryWkDiv     OR @QryWkDiv ='')   -- 1000726004
         AND (A.WorkOperSeq   = @WorkOperSeq  OR @WorkOperSeq ='')    
         AND (L.DivSeq  = @EmpSeq OR @EmpSeq = 0)
         AND (A.DeptClassSeq  = @DeptClassSeq OR @DeptClassSeq = 0)
    */ 
  RETURN
GO 
exec KPXCM_SEQWorkOrderResultListQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <QryWkDiv />
    <EmpSeq />
    <DeptClassSeq />
    <QryAccUnitSeq>2</QryAccUnitSeq>
    <QryFrDate>20150701</QryFrDate>
    <QryToDate>20150723</QryToDate>
    <QryProgType />
    <WorkOperSeq />
    <QryWorkOperSerl />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031032,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025872
