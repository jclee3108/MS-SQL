
IF OBJECT_ID('yw_SPUToolPartDelvItemListJump') IS NOT NULL
    DROP PROC yw_SPUToolPartDelvItemListJump
GO

-- v2013.07.12

-- �����ǰ��ǰǰ����ȸ_yw(������ȸ) by����õ
CREATE PROC yw_SPUToolPartDelvItemListJump                
    @xmlDocument    NVARCHAR(MAX),            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0
AS        
    
	CREATE TABLE #TPUDelv (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelv'     
	IF @@ERROR <> 0 RETURN  
      
    SELECT T.ToolName, -- �����   
           T.ToolNo, -- �����ȣ
           T.Spec, -- ����԰�
           T.ToolSeq,
           H.MinorName AS UMToolKindName, -- ��������
           T.UMToolKind, -- ���������ڵ�
           G.ItemName AS ItemName, 
           B.ItemSeq AS ItemSeq, 
           G.ItemNo, 
           G.Spec AS ItemSpec,
           I.UnitName,
           F.Qty,
           CONVERT(NVARCHAR(10),GetDate(),112) AS RepairDate, -- ������
           J.EmpName,
           T.EmpSeq
           
             
      FROM #TPUDelv     AS A   
      JOIN _TPUDelvItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq AND B.DelvSerl = A.DelvSerl ) 
      JOIN _TPUDelv     AS C WITH(NOLOCK) ON ( C.DelvSeq = B.DelvSeq )
      JOIN _TPDTool     AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.ToolSeq = B.Memo7 ) 
      LEFT OUTER JOIN _TDAItem                AS G WITH(NOLOCK) ON ( B.CompanySeq = G.CompanySeq AND B.ItemSeq = G.ItemSeq ) 
      LEFT OUTER JOIN _TPUORDPOItem           AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND B.ProgFromSeq = D.POSeq AND B.ProgFromSerl = D.POSerl ) 
      LEFT OUTER JOIN _TPUORDApprovalReqItem  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND D.ProgFromSeq = E.ApproReqSeq AND D.ProgFromSerl = E.ApproReqSerl ) 
      LEFT OUTER JOIN _TPUORDPOReqItem        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND E.ProgFromSeq = F.POReqSeq AND E.ProgFromSerl = F.POReqSerl ) 
      LEFT OUTER JOIN _TDAUMinor              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = T.UMToolKind ) 
      LEFT OUTER JOIN _TDAUnit                AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAEmp                 AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = T.EmpSeq ) 

    RETURN
GO
