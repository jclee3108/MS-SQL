
IF OBJECT_ID('KPXCM_SPDBOMBatchItemQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchItemQuery
GO 

-- v2015.09.16 

/*************************************************************************************************  
 FORM NAME           -       FrmPDBOMBatch  
 DESCRIPTION         -     ���պ� ��������ȸ  
 CREAE DATE          -       2008.05.30      CREATE BY: ����  
 LAST UPDATE  DATE   -       2008.06.11         UPDATE BY: ����  
                             2009.09.09         UPDATE BY �۰��  
                           :: ����, Overage, ����Է�, ���ޱ��� �߰�  
                             2009.09.16         UPDATE BY �۰��  
                           :: ǰ���ڻ�з� �߰�  
                             2009.09.17         UPDATE BY �۰��  
                           :: ǰ���ڻ�з��� �߰�  
                             2011.04.30         UPDATE BY ������  
                           :: ���ļ���, ���������, ���������� �߰�  
*************************************************************************************************/  
CREATE PROCEDURE KPXCM_SPDBOMBatchItemQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    DECLARE @docHandle INT,  
            @BatchSeq  INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @BatchSeq      = BatchSeq  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  BatchSeq        INT)  
  
    SELECT A.BatchSeq    , A.Serl            , A.ItemSeq           , B.ItemName, B.ItemNo,  
           B.Spec        , C.UnitName        , B.UnitSeq           ,  
           (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = A.CompanySeq AND UnitSeq = A.InputUnitSeq) AS InputUnitName,  
           A.InputUnitSeq, A.NeedQtyNumerator, A.NeedQtyDenominator, A.Remark  
   , A.ProcSeq    AS ProcSeq     -- �����ڵ�  
   , D.ProcName   AS ProcName     -- ������  
         , A.Overage    AS Overage      -- Overage(%)  
         , A.AvgContent AS AvgContent   -- ����Է�(%)  
         , A.SMDelvType AS SMDelvType   -- ���ޱ���  
         , B.AssetSeq   AS AssetSeq     -- ǰ���ڻ�з�  
         , E.AssetName  AS AssetName    -- ǰ���ڻ�з���  
         , A.SortOrder                  -- ���ļ���  
         , A.DateFr                     -- ���������  
         , A.DateTo                     -- ����������  
      FROM KPXCM_TPDBOMBatchItem AS A WITH(NOLOCK)  
           LEFT OUTER JOIN _TDAItem AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq  
           LEFT OUTER JOIN _TDAUnit AS C ON B.CompanySeq = C.CompanySeq AND B.UnitSeq = C.UnitSeq  
           LEFT OUTER JOIN _TPDBaseProcess AS D ON A.CompanySeq = D.CompanySeq AND A.ProcSeq = D.ProcSeq  
           LEFT OUTER JOIN _TDAItemAsset    AS E ON A.CompanySeq = E.CompanySeq AND B.AssetSeq = E.AssetSeq  
  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.BatchSeq   = @BatchSeq  
     ORDER BY A.SortOrder, A.Serl  
  
  
RETURN  
/*****************************************************************************/  