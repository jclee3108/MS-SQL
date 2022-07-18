IF OBJECT_ID('KPXCM_SPDBOMBatchFactQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchFactQuery
GO 

-- v2015.09.16 
/*************************************************************************************************  
  FORM NAME           -       FrmPDBOMBatchFact
  DESCRIPTION         -     ����庰 ���պ� ��ȸ
  CREAE DATE          -       2008.09.02      CREATE BY: ����
  LAST UPDATE  DATE   -       2008.09.02         UPDATE BY: ����
                              2009.09.21         UPDATE BY: �۰��
                           :: ��ȸ���� - �����帧����, ǰ�� �߰�, ��Ʈ�÷� - �����帧����, BOM���� �߰�
 *************************************************************************************************/  
 CREATE PROCEDURE KPXCM_SPDBOMBatchFactQuery  
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
  
 AS       
     DECLARE @docHandle  INT          ,
             @ItemName   NVARCHAR(400),
             @BatchName  NVARCHAR(100),
             @BatchNo    NVARCHAR(12),
             @FactUnit   INT,
             @ProcTypeSeq    INT,         -- �����帧�����ڵ�
             @ItemNo     NVARCHAR(100)    -- ǰ��
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
      SELECT  @ItemName      = ItemName , 
             @BatchName     = BatchName,
             @BatchNo       = BatchNo  ,
             @FactUnit      = FactUnit ,
             @ProcTypeSeq   = ProcTypeSeq,
             @ItemNo        = ItemNo 
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
     WITH (  ItemName        NVARCHAR(400),
             BatchName       NVARCHAR(100),
             BatchNo         NVARCHAR(12) ,
             FactUnit        INT          ,
             ProcTypeSeq     INT          ,
             ItemNo          NVARCHAR(100)   )
      SELECT A.BatchSeq, A.FactUnit , A.BatchNo  , A.BatchName  , A.ItemSeq  ,
            B.ItemNo  , A.BatchSize, A.BatchName, A.ProdUnitSeq, A.IsUse    ,
            A.Remark  , B.ItemName , A.DateFr   , A.DateTo     , A.IsDefault
          , A.BOMRev  , A.ProcTypeSeq, C.ProcTypeName 
       FROM KPXCM_TPDBOMBatch AS A WITH(NOLOCK) 
            LEFT OUTER JOIN _TDAItem AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq
            LEFT OUTER JOIN _TPDProcType AS C ON A.CompanySeq = C.CompanySeq AND A.ProcTypeSeq = C.ProcTypeSeq
      WHERE A.CompanySeq = @CompanySeq
        AND (@ItemName  = ''    OR B.ItemName  LIKE @ItemName  + '%')
        AND (@BatchName = ''    OR A.BatchName LIKE @BatchName + '%')
        AND (@BatchNo   = ''    OR A.BatchNo   LIKE @BatchNo   + '%')
        AND (@FactUnit  = 0     OR A.FactUnit  = @FactUnit)
        AND (@ProcTypeSeq  = 0  OR A.ProcTypeSeq  = @ProcTypeSeq)
        AND (@ItemNo    = ''    OR B.ItemNo    LIKE @ItemNo + '%')
  RETURN  
 /**************************************************************************************************/