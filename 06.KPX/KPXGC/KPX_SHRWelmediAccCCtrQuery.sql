
IF OBJECT_ID('KPX_SHRWelmediAccCCtrQuery') IS NOT NULL 
    DROP PROC KPX_SHRWelmediAccCCtrQuery
GO 

-- v2014.12.08 

-- �Ƿ��������(Ȱ������)-��ȸ by����õ
CREATE PROCEDURE KPX_SHRWelmediAccCCtrQuery  
    @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML�� ����  
    @xmlFlags    INT = 0         ,    -- �ش� XML�� TYPE  
    @ServiceSeq  INT = 0         ,    -- ���� ��ȣ  
    @WorkingTag  NVARCHAR(10)= '',    -- ��ŷ �±�  
    @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ  
    @LanguageSeq INT = 1         ,    -- ��� ��ȣ  
    @UserSeq     INT = 0         ,    -- ����� ��ȣ  
    @PgmSeq      INT = 0              -- ���α׷� ��ȣ  

AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    -- ����� ������ �����Ѵ�.  
    DECLARE @docHandle  INT, 
            @EnvValue   INT, 
            @YM         NCHAR(6), 
            @GroupSeq   INT 
    
    -- XML�Ľ�  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument�� XML�� @docHandle�� �ڵ��Ѵ�.  
    
    -- XML�� DataBlock1���κ��� ���� ������ ������ �����Ѵ�.  
    SELECT @EnvValue       = ISNULL(EnvValue,0),  
           @YM             = ISNULL(YM,''),
           @GroupSeq       = ISNULL(GroupSeq,0)
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML�� DataBlock1���κ���  
      WITH (
            EnvValue       INT,  
            YM             NCHAR(6),
            GroupSeq       INT
           )  
    
    SELECT A.WelCodeName, 
           A.WelCodeSeq, 
           B.AccSeq AS AccSeq,
           C.AccName,
           B.UMCostType, 
           D.MinorName AS UMCostTypeName,
           B.OppAccSeq, 
           E.AccName AS OppAccName,
           B.VatAccSeq, 
           F.AccName AS VatAccName 
    
      FROM KPX_THRWelCode                   AS A 
      LEFT OUTER JOIN KPX_THRWelmediAccCCtr AS B ON ( B.CompanySeq  = @CompanySeq 
                                                  AND A.WelCodeSeq  = B.WelCodeSeq 
                                                  AND B.EnvValue    = @EnvValue 
                                                  AND B.YM          = @YM   
                                                  AND B.GroupSeq    = @GroupSeq
                                                    ) 
      LEFT OUTER JOIN _TDAAccount           AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = B.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.UMCostType ) 
      LEFT OUTER JOIN _TDAAccount           AS E ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = B.OppAccSeq ) 
      LEFT OUTER JOIN _TDAAccount           AS F ON ( F.CompanySeq = @CompanySeq AND F.AccSeq = B.VATAccSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
    
    RETURN
GO 
exec KPX_SHRWelmediAccCCtrQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <EnvValue>5518002</EnvValue>
    <YM>201001</YM>
    <GroupSeq>7</GroupSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026567,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022249