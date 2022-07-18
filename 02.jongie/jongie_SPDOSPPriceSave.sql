  
IF OBJECT_ID('jongie_SPDOSPPriceSave') IS NOT NULL   
    DROP PROC jongie_SPDOSPPriceSave  
GO  
  
-- v2013.09.24 
  
-- ��ǥ���ְŷ�ó�ܰ��ϰ�����_jongie by����õ   
CREATE PROC jongie_SPDOSPPriceSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @Status   INT, 
            @Result   NVARCHAR(200), 
            @EnvSeq8  INT, 
            @EnvSeq9  INT, 
            @EnvName8 NVARCHAR(100)
    
    SELECT @Status = 0  
    SELECT @Result = '' 
    SELECT @EnvSeq8 = EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1 -- ��ǥ���ְŷ�ó
    SELECT @EnvSeq9 = EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 9 AND EnvSerl = 1 -- �ŷ�ó����
    SELECT @EnvName8 = CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8 -- ��ǥ���ְŷ�ó��

    -- üũ2, ��ǥ���ְŷ�ó(OOO)�� �ܰ��� ��ϵǾ� ���� �ʽ��ϴ�.
    IF NOT EXISTS (SELECT 1 FROM _TPDOSPPriceItem WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8)
    BEGIN 
        SELECT @Status = 2
        SELECT @Result = N'��ǥ���ְŷ�ó('+RTRIM(@EnvName8)+')�� �ܰ��� ��ϵǾ� ���� �ʽ��ϴ�.'
    END
    -- üũ2, END
    
    -- üũ3, �߰�����Mapping������ ��ǥ���ְŷ�ó�� ���ְ���� ����ó�� �������� �ʽ��ϴ�.
    IF NOT EXISTS (SELECT 1 FROM _TPDOSPPrice WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8)
    BEGIN 
        SELECT @Status = 3
        SELECT @Result = N'�߰�����Mapping������ ��ǥ���ְŷ�ó�� ���ְ���� ����ó�� �������� �ʽ��ϴ�.'
    END
    -- üũ3, END
    
    -- üũ1, �߰�����Mapping������ ��ǥ���ְŷ�ó�� �����ϼ���.
    IF (SELECT EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1) = 0 
    OR (SELECT EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1) = '' 
    BEGIN 
        SELECT @Status = 1
        SELECT @Result = N'�߰�����Mapping������ ��ǥ���ְŷ�ó�� �����ϼ���.'
    END
    -- üũ1, END 

    -- ���ǿ� �����ϴ� ����ó ���
    SELECT A.CustSeq, @Status AS Status, @Result AS Result
      INTO #TPDOSPPrice
      FROM _TPDOSPPrice AS A
      JOIN _TDACustKind AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq AND B.UMCustKind = @EnvSeq9 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (SELECT COUNT(1) FROM _TDACustKind WHERE CompanySeq = @CompanySeq AND A.CustSeq = CustSeq GROUP BY CustSeq) = 1 
       AND A.CustSeq <> @EnvSeq8 
       
    -- ��ǥ���ְŷ�ó �ܰ� ������ ���
    SELECT CompanySeq , FactUnit , CustSeq      , ItemSeq  , Serl      , 
           ItemBomRev , ProcRev  , AssySeq      , CurrSeq  , OSPType   , 
           PriceType  , Price    , ProcPrice    , MatPrice , StartDate ,
           EndDate    , ProcSeq  , PriceUnitSeq , Remark   , IsStop    ,
           StopRemark , StopDate , StopEmpSeq 
      INTO #TPDOSPPriceItem
      FROM _TPDOSPPriceItem 
     WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8 
    
    -- ���ǿ� �����ϴ� ����ó�� �ܰ� ������ �����
    DELETE B
      FROM #TPDOSPPrice     AS A 
      JOIN _TPDOSPPriceItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
     WHERE A.Status = 0 
    
    -- ��ǥ���ְŷ�ó �����͸� ���ǿ� �����ϴ� ���ְŷ�ó�� ���� �� �־��ֱ�(�ܰ�����)
    INSERT INTO _TPDOSPPriceItem(
                                 CompanySeq   , FactUnit , CustSeq      , ItemSeq  , Serl        , 
                                 ItemBomRev   , ProcRev  , AssySeq      , CurrSeq  , OSPType     , 
                                 PriceType    , Price    , ProcPrice    , MatPrice , StartDate   , 
                                 EndDate      , ProcSeq  , PriceUnitSeq , Remark   , LastUserSeq , 
                                 LastDateTime , IsStop   , StopRemark   , StopDate , StopEmpSeq
                                )
    SELECT @CompanySeq  , B.FactUnit , A.CustSeq      , B.itemSeq  , B.Serl       , 
           B.ItemBomRev , B.ProcRev  , B.AssySeq      , B.CurrSeq  , B.OSPType    , 
           B.PriceType  , B.Price    , B.ProcPrice    , B.MatPrice , B.StartDate  , 
           B.EndDate    , B.ProcSeq  , B.PriceUnitSeq , B.Remark   , @UserSeq     , 
           GETDATE()    , B.IsStop   , B.StopRemark   , B.StopDate , B.StopEmpSeq
      FROM #TPDOSPPrice AS A 
      JOIN #TPDOSPPriceItem AS B WITH(NOLOCK) ON ( 1 = 1 )
     WHERE A.Status = 0 
     ORDER BY A.CustSeq

    -- ��ǥ���ְŷ�ó �ҿ��������� ���
    SELECT CompanySeq  , FactUnit  , CustSeq          , GoodItemSeq        , Serl         , 
           SubSerl     , ItemSeq   , UnitSeq          , Qty                , StdUnitSeq   , 
           StdUnitQty  , Remark    , NeedQtyNumerator , NeedQtyDenominator , SMDelvType   , 
           OutLossRate , QtyPerOne , IsDirect         , LastUserSeq        , LastDateTime , 
           IsSale      , Price 
      INTO #TPDOSPPriceSubItem
      FROM _TPDOSPPriceSubItem 
     WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8 
    
    -- ���ǿ� �����ϴ� ����ó�� �ҿ��������� �����
    DELETE B
      FROM #TPDOSPPrice        AS A 
      JOIN _TPDOSPPriceSubItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
     WHERE A.Status = 0 
    
    -- ��ǥ���ְŷ�ó �����͸� ���ǿ� �����ϴ� ���ְŷ�ó�� ���� �� �־��ֱ�(�ҿ���������)
    INSERT INTO _TPDOSPPriceSubItem(
                                    CompanySeq  , FactUnit  , CustSeq          , GoodItemSeq        , Serl         , 
                                    SubSerl     , ItemSeq   , UnitSeq          , Qty                , StdUnitSeq   , 
                                    StdUnitQty  , Remark    , NeedQtyNumerator , NeedQtyDenominator , SMDelvType   , 
                                    OutLossRate , QtyPerOne , IsDirect         , LastUserSeq        , LastDateTime ,
                                    IsSale      , Price                                
                                   )
    SELECT @CompanySeq   , B.FactUnit  , A.CustSeq          , B.GoodItemSeq        , B.Serl       , 
           B.SubSerl     , B.ItemSeq   , B.UnitSeq          , B.Qty                , B.StdUnitSeq , 
           B.StdUnitQty  , B.Remark    , B.NeedQtyNumerator , B.NeedQtyDenominator , B.SMDelvType , 
           B.OutLossRate , B.QtyPerOne , B.IsDirect         , @UserSeq             , GETDATE()    ,
           B.IsSale      , B.Price  
      FROM #TPDOSPPrice        AS A 
      JOIN #TPDOSPPriceSubItem AS B WITH(NOLOCK) ON ( 1 = 1 )
     WHERE A.Status = 0 
     ORDER BY A.CustSeq
    
    SELECT @Status AS Status, @Result AS Result

    RETURN  

GO

BEGIN TRAN
exec jongie_SPDOSPPriceSave @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1017952,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1088
ROLLBACK TRAN 
