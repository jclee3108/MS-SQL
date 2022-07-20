     
IF OBJECT_ID('mnpt_SPJTOperatorPriceSubItemQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTOperatorPriceSubItemQuery      
GO      
      
-- v2017.09.19
      
-- ���������Ӵܰ��Է�-SS3��ȸ by ����õ  
CREATE PROC mnpt_SPJTOperatorPriceSubItemQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @StdSeq  INT, 
            @StdSerl INT  
      
    SELECT @StdSeq   = ISNULL( StdSeq, 0 ), 
           @StdSerl  = ISNULL( StdSerl, 0 )
      FROM #BIZ_IN_DataBlock2    
    
    
    -- ������ȸ
    SELECT A.StdSeq            , 
           A.StdSerl           , 
           A.StdSubSerl        , 
           A.PJTTypeSeq        , -- ȭ���ڵ� 
           B.PJTTypeName       , -- ȭ�� 
           A.UnDayPrice        , -- �����ϴ� 
           A.UnHalfPrice       , -- ��������
           A.UnMonthPrice      , -- ��������
           A.DailyDayPrice     , -- �Ͽ��ϴ� 
           A.DailyHalfPrice    , -- �Ͽ����
           A.DailyMonthPrice   , -- �Ͽ���� 
           A.OSDayPrice        , -- OS�ϴ� 
           A.OSHalfPrice       , -- OS���� 
           A.OSMonthPrice      , -- OS���� 
           A.EtcDayPrice       , -- ��Ÿ�ϴ� 
           A.EtcHalfPrice      , -- ��Ÿ���� 
           A.EtcMonthPrice       -- ��Ÿ���� 

      FROM mnpt_TPJTOperatorPriceSubItem    AS A  
      LEFT OUTER JOIN _TPJTType             AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTTypeSeq = A.PJTTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.StdSeq = @StdSeq 
       AND A.StdSerl = @StdSerl 
    
    RETURN     
    