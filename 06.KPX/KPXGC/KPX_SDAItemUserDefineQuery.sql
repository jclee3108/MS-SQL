
IF OBJECT_ID('KPX_SDAItemUserDefineQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemUserDefineQuery
GO 

-- v2014.11.04 

-- �߰�������ȸ by����õ 

-- Ver.20140915
  /*********************************************************************************************************************
     ȭ��� : ǰ���� - �߰�������ȸ
     SP Name: _SDAItemUserDefineQuery
     �ۼ��� : 2009.10.27 : CREATEd by ������
     ������ : 2010.09.27 ������
                 ����ǰ�� ��쿡 @PgmSeq = 6061 : ǰ����(����) �߰�
                 ��ȸ��� order by�� �߰��������ǿ��� ������ ��ȸ������ ����
              2011-12-23 ����
                 ������ ��쿡 @PgmSeq = 6063: ������(����) �߰�
              2013-07-18 õ���
                 DecLen �÷� �߰�
 ********************************************************************************************************************/
  -- ǰ���� - ǰ��з�Tab �ʵ� �Ӽ� 
 CREATE PROC KPX_SDAItemUserDefineQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
      DECLARE @docHandle      INT,
             @ItemSeq        INT,
             @AssetTyep      INT
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT @ItemSeq = ISNULL(ItemSeq,0)
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH ( ItemSeq INT )
       
    CREATE TABLE #tmp 
    (
        TitleSerl       INT, 
        Title           NVARCHAR(50), 
        MngValName      NVARCHAR(100), 
        SMInputType     INT, 
        Seq             INT, 
        MngValText      NVARCHAR(100), 
        CodeHelpSeq     INT, 
        CodeHelpParams  NVARCHAR(100), 
        Mask            NVARCHAR(100), 
        IsNON           NCHAR(1), 
        QrySort         INT, 
        DecLen          INT
    ) 
    
    IF @PgmSeq = 1021310 
    BEGIN 
        INSERT INTO #tmp 
        (
            TitleSerl     ,     Title         ,     MngValName    ,     SMInputType   ,     Seq           ,     
            MngValText    ,     CodeHelpSeq   ,     CodeHelpParams,     Mask          ,     IsNON         ,     
            QrySort       ,     DecLen        
         )
        SELECT A.TitleSerl          AS TitleSerl,
               A.Title              AS Title,
               ''                   AS MngValName,
               A.SMInputType        AS SMInputType,
               ISNULL(B.MngValSeq,0)   AS Seq,
               B.MngValText         AS MngValText,
               A.CodeHelpConst      AS CodeHelpSeq,
               A.CodeHelpParams     AS CodeHelpParams,
               A.MaskAndCaption     AS Mask,
               A.IsEss              AS IsNON,
               A.QrySort,
               A.DecLen
           FROM _TCOMUserDefine               AS A WITH(NOLOCK)
           LEFT OUTER JOIN KPX_TDAItemUserDefine AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = @ItemSeq AND A.TitleSerl = B.MngSerl )
          WHERE A.CompanySeq    = @CompanySeq
            AND A.TableName     = '_TDAItem'
            AND (@PgmSeq IN (1021310) AND A.DefineUnitSeq = 8010001) -- ����ǰ : 1197(ǰ����), 6061(ǰ����(����)), 6815(ǰ�������ϰ�����)
                 --OR (@PgmSeq IN (1199,6063,10444,12012) AND A.DefineUnitSeq = 8010002))  -- ����   : 1199(������), 6063(������(����)), 10444(���������ϰ�����),12012(���������ϰ�����(����))
    END 
    ELSE IF @PgmSeq IN ( 1021312, 1021313 ) 
    BEGIN
        INSERT INTO #tmp 
        (
            TitleSerl     ,     Title         ,     MngValName    ,     SMInputType   ,     Seq           ,     
            MngValText    ,     CodeHelpSeq   ,     CodeHelpParams,     Mask          ,     IsNON         ,     
            QrySort       ,     DecLen        
         )
        SELECT A.TitleSerl          AS TitleSerl,
               A.Title              AS Title,
               ''                   AS MngValName,
               A.SMInputType        AS SMInputType,
               ISNULL(B.MngValSeq,0)   AS Seq,
               B.MngValText         AS MngValText,
               A.CodeHelpConst      AS CodeHelpSeq,
               A.CodeHelpParams     AS CodeHelpParams,
               A.MaskAndCaption     AS Mask,
               A.IsEss              AS IsNON,
               A.QrySort,
               A.DecLen
           FROM _TCOMUserDefine               AS A WITH(NOLOCK)
           LEFT OUTER JOIN _TDAItemUserDefine AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = @ItemSeq AND A.TitleSerl = B.MngSerl )
          WHERE A.CompanySeq    = @CompanySeq
            AND A.TableName     = '_TDAItem'
            AND (@PgmSeq IN (1021312, 1021313) AND A.DefineUnitSeq = 8010001) -- ����ǰ : 1197(ǰ����), 6061(ǰ����(����)), 6815(ǰ�������ϰ�����)
                 --OR (@PgmSeq IN (1199,6063,10444,12012) AND A.DefineUnitSeq = 8010002))  -- ����   : 1199(������), 6063(������(����)), 10444(���������ϰ�����),12012(���������ϰ�����(����))
        
    END 
    
    EXEC _SCOMGetCodeHelpDataName @CompanySeq, @LanguageSeq, '#tmp'
     
    SELECT A.TitleSerl         AS MngSerl,
           A.Title             AS MngName,
           CASE WHEN A.SMInputType IN ( 1027003, 1027005 ) THEN isnull(A.ValueName,'')
           ELSE ISNULL(A.MngValText,'') END AS MngValName,
           A.Seq               AS MngValSeq,
           A.CodeHelpSeq       AS CodeHelpSeq,
           A.CodeHelpParams    AS CodeHelpParams,
           A.Mask              AS Mask,
           A.SMInputType       AS SMInputType,
           A.IsNON             AS IsNON,
           A.DecLen            AS DecLen
      FROM #tmp AS A
     ORDER BY A.QrySort
    
    RETURN
    go 
exec KPX_SDAItemUserDefineQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemSeq>1051544</ItemSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025575,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021312