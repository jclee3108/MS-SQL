IF OBJECT_ID('KPXCM_SPDBOMBatchItemSave') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchItemSave
GO 

-- v2015.09.16 

/*************************************************************************************************  
 FORM NAME           -       FrmPDBOMBatch  
 DESCRIPTION         -     ���պ�  
 CREAE DATE          -       2008.05.30      CREATE BY: ����  
 LAST UPDATE  DATE   -       2008.06.11         UPDATE BY: ����  
                             2009.09.09         UPDATE BY �۰��  
                           :: ����, Overage, ����Է�, ���ޱ��� �߰�  
                             2011.04.30         UPDATE BY ������  
                           :: ���ļ���, ���������, ���������� �߰�  
*************************************************************************************************/  
CREATE PROCEDURE KPXCM_SPDBOMBatchItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    DECLARE @docHandle  INT,  
            @Serl       INT  
  
    -- BatchItem�� ���� ���� �������� ����  
    CREATE TABLE #KPXCM_TPDBOMBatchItem (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDBOMBatchItem'  
  
    IF @@ERROR <> 0 RETURN  
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    'KPXCM_TPDBOMBatchItem', -- �����̺��  
                    '#KPXCM_TPDBOMBatchItem', -- �������̺��  
                    'BatchSeq, Serl' , -- Ű�� �������� ���� , �� �����Ѵ�.  
                    'CompanySeq, BatchSeq, Serl, ItemSeq, InputUnitSeq, NeedQtyNumerator, NeedQtyDenominator,  Remark, LastUserSeq, LastDateTime'  
    -- DELETE  
    IF EXISTS (SELECT TOP 1 1 FROM #KPXCM_TPDBOMBatchItem WHERE WorkingTag = 'D' AND Status = 0  )  
    BEGIN  
        DELETE KPXCM_TPDBOMBatchItem  
          FROM KPXCM_TPDBOMBatchItem A JOIN #KPXCM_TPDBOMBatchItem B ON (A.BatchSeq = B.BatchSeq AND A.Serl = B.Serl)  
         WHERE B.WorkingTag = 'D' AND B.Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END  
  
    -- Update  
    IF EXISTS (SELECT 1 FROM #KPXCM_TPDBOMBatchItem WHERE WorkingTag = 'U' AND Status = 0  )  
    BEGIN  
        UPDATE KPXCM_TPDBOMBatchItem SET  
                ItemSeq             = B.ItemSeq,  
                InputUnitSeq        = B.InputUnitSeq,  
                NeedQtyNumerator    = B.NeedQtyNumerator,  
                NeedQtyDenominator  = B.NeedQtyDenominator,  
                Remark              = B.Remark,  
                LastUserSeq      = @UserSeq,  
                LastDateTime      = GETDATE(),  
                ProcSeq             = B.ProcSeq,  
                Overage             = B.Overage,  
                AvgContent          = B.AvgContent,  
                SMDelvType          = B.SMDelvType,  
                SortOrder           = B.SortOrder,  
                DateFr              = B.DateFr,  
                DateTo              = B.DateTo  
          FROM KPXCM_TPDBOMBatchItem AS A JOIN #KPXCM_TPDBOMBatchItem AS B ON (A.BatchSeq = B.BatchSeq AND A.Serl = B.Serl)  
         WHERE B.WorkingTag = 'U' AND B.Status = 0  
           AND A.CompanySeq  = @CompanySeq  
  
        IF @@ERROR <> 0 RETURN  
    END  
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #KPXCM_TPDBOMBatchItem WHERE WorkingTag = 'A' AND Status = 0  )  
    BEGIN  
        -- MAX UnitSeq  
        SELECT @Serl = ISNULL((SELECT MAX(A.Serl) FROM KPXCM_TPDBOMBatchItem AS A WITH(NOLOCK)  
                                                       JOIN #KPXCM_TPDBOMBatchItem AS B WITH(NOLOCK) ON A.BatchSeq = B.BatchSeq  
                                                 WHERE A.CompanySeq = @CompanySeq), 0)  
  
        UPDATE #KPXCM_TPDBOMBatchItem SET Serl = @Serl+DataSeq  
         WHERE WorkingTag = 'A' AND Status = 0  
  
    -- ���� INSERT  
        INSERT INTO KPXCM_TPDBOMBatchItem (CompanySeq      , BatchSeq          , Serl        , ItemSeq     , InputUnitSeq,  
                                      NeedQtyNumerator, NeedQtyDenominator, Remark      , LastUserSeq , LastDateTime,  
                                        ProcSeq         , Overage           , AvgContent  , SMDelvType,  
                                      SortOrder       , DateFr            , DateTo)  
        SELECT @CompanySeq       , B.BatchSeq          , B.Serl         , B.ItemSeq, B.InputUnitSeq,  
               B.NeedQtyNumerator, B.NeedQtyDenominator, B.Remark       , @UserSeq , GETDATE(),  
               B.ProcSeq         , B.Overage           , B.AvgContent   , B.SMDelvType,  
               ISNULL(B.SortOrder, 0), ISNULL(B.DateFr, ''), ISNULL(B.DateTo, '')  
          FROM #KPXCM_TPDBOMBatchItem AS B  
         WHERE B.WorkingTag = 'A' AND B.Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END  
  
    SELECT * FROM #KPXCM_TPDBOMBatchItem AS KPXCM_TPDBOMBatchItem  
  
RETURN  
/*************************************************************************************************/  