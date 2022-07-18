  
IF OBJECT_ID('KPX_SEIS_PL_MOD_PLANQuerySub') IS NOT NULL   
    DROP PROC KPX_SEIS_PL_MOD_PLANQuerySub  
GO  
  
-- v2014.11.24  
  
-- (�濵����)���� ���� ��ȹ-�����Ͱ������� by ����õ   
CREATE PROC KPX_SEIS_PL_MOD_PLANQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   

      
    CREATE TABLE #KPX_TEIS_PL_MOD_PLAN (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_PL_MOD_PLAN'   
    IF @@ERROR <> 0 RETURN    
    
    
    DECLARE @BizUnit            INT,  
            @PlanYM             NCHAR(6), 
            @ToAccYM            NCHAR(6), 
            @FrSttlYM           NCHAR(6), 
            @ToSttlYM           NCHAR(6), 
            @FormatSeq          INT, 
            @IsUseUMCostType    NCHAR(1), 
            @argLanguageSeq     INT 
    
    SELECT @BizUnit = ( SELECT TOP 1 BizUnit FROM #KPX_TEIS_PL_MOD_PLAN ) 
    SELECT @PlanYM = ( SELECT TOP 1 PlanYM FROM #KPX_TEIS_PL_MOD_PLAN ) 
    
    
    IF LEN(LTRIM(RTRIM(ISNULL(@PlanYM,'')))) = 6  
    BEGIN  
        SELECT @ToAccYM = @PlanYM  
    END  
    ELSE  
    BEGIN  
    
    -- 1�������� �ƴ� ��� ���⵵�� �����͸� �������� ��찡 �߻��Ͽ� ������ 2011.08.18 dykim  
        SELECT @ToAccYM = FrSttlYM   
          FROM _TDAAccFiscal   
         WHERE CompanySeq = @CompanySeq  
           AND FiscalYear = LEFT(@PlanYM,4)   
    END  
    
    EXEC _SACGetAccTerm @CompanySeq     = @CompanySeq       ,  
                        @CurrDate       = @ToAccYM        ,  
                        @FrYM           = @FrSttlYM OUTPUT      ,  
                        @ToYM           = @ToSttlYM OUTPUT        
    
    -- �繫��ǥ���������� ����  
    SELECT TOP 1 @FormatSeq   = A.FormatSeq,           -- �繫��ǥ�����ڵ�  
                 @IsUseUMCostType = B.IsUseUMCostType  -- ��뱸�� ��뿩��  
      FROM _TCOMFSForm AS A WITH (NOLOCK)  
      JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq    
      JOIN _TCOMFSKind AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.FSKindSeq = C.FSKindSeq    
     WHERE A.CompanySeq   = @CompanySeq  
       AND C.FSKindNo     = 'IS'                  -- �繫��ǥ�����ڵ�  
       AND A.FSDomainSeq  = 11               -- �繫��ǥ��������  
       AND A.IsDefault    = '1'   
       AND @ToAccYM BETWEEN A.FrYM AND A.ToYM          -- �Ⱓ���� �ϳ��� ����  
    
    -- ��뱸�� ��뿩�θ� �о�´�.    
    SELECT  @IsUseUMCostType = B.IsUseUMCostType    
      FROM _TCOMFSForm AS A WITH (NOLOCK)    
      JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq    
     WHERE A.CompanySeq   = @CompanySeq    
       AND A.FormatSeq    = @FormatSeq    
    
    CREATE TABLE #Temp  
    (  
        RowNum      INT IDENTITY(0, 1)  
    )  
    
    ALTER TABLE #Temp ADD ThisTermItemAmt       DECIMAL(19, 5)  -- ����׸�ݾ�  
    ALTER TABLE #Temp ADD ThisTermAmt           DECIMAL(19, 5)  -- ���ݾ�  
    ALTER TABLE #Temp ADD PrevTermItemAmt       DECIMAL(19, 5)  -- �����׸�ݾ�  
    ALTER TABLE #Temp ADD PrevTermAmt           DECIMAL(19, 5)  -- ����ݾ�  
    ALTER TABLE #Temp ADD PrevChildAmt          DECIMAL(19, 5)  -- �����ݾ�  
    ALTER TABLE #Temp ADD ThisChildAmt          DECIMAL(19, 5)  -- �����ݾ�  
    ALTER TABLE #Temp ADD ThisReplaceFormula    NVARCHAR(1000)   -- ���ݾ�  
    ALTER TABLE #Temp ADD PrevReplaceFormula    NVARCHAR(1000)   -- ����ݾ�   
    -- �繫��ǥ �⺻ �ʱ� ���� ����  
    EXEC _SCOMFSFormInit @CompanySeq, @FormatSeq, @argLanguageSeq, '#Temp'  
    IF @@ERROR <> 0  RETURN  
    
    -- ǥ�þ�Ŀ��� �������� �ʵ��� �ϱ� ���� 1�� ������Ʈ�Ѵ�.  
    UPDATE  #Temp  
       SET  ThisTermAmt  = 1  
    
    -- ǥ�þ�� ����  
    EXEC _SCOMFSFormApplyStyle @CompanySeq, @FormatSeq, '#Temp', '0'--, @IsDisplayZero  
    IF @@ERROR <> 0  RETURN  
    
    UPDATE A 
       SET AccSeq = B.FSItemSeq, 
           AccName = B.FSItemNamePrt
      from #KPX_TEIS_PL_MOD_PLAN AS A 
      JOIN #Temp                 AS B ON ( A.AccName = LTRIM(B.FSItemNamePrt) ) 
    
    SELECT AccName, 
           AccSeq, 
           EstAmt, 
           ModAmt 
      FROM #KPX_TEIS_PL_MOD_PLAN 

    RETURN  
GO 
exec KPX_SEIS_PL_MOD_PLANQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <AccName>  I. ��    ��</AccName>
    <ModAmt>123124</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>    (1) �����ڻ�</AccName>
    <ModAmt>123123</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>      1. �����ڻ�</AccName>
    <ModAmt>34234</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        1) ���ݹ����ݼ��ڻ�</AccName>
    <ModAmt>123123</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               ����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1.</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2.</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. ���¿���</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. ���ܿ���</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. ��Ÿ����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          6. test����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               ��������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        2) �ܱ������ڻ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. �ܱ������ڻ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. �ܱ⿹��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. �ܱ�����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. �ܱ�Ÿ�����(��������)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. ��ȭ���⿹��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        3) ��Ÿ �����ڻ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        4) ����ä��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               �ܻ����ݴ������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ��ȭ�ܻ�����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               ��ȭ�ܻ����ݴ������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. ��������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               �������� �������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. �ε�����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. �ε����� �������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. �ܻ�����(����)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               �ܻ�����(û��)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          6. �ܻ�����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        5) �ܱ�뿩��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. �ܱ�뿩��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. �ܱ�뿩�� �������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. �����뿩��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. �����뿩�� �������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. ��.��.�� �ܱ�뿩��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        6) �̼�����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. �̼�����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               �̼����� �������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        7) ���ޱ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ���ޱ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               ���ޱ� �������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               ��������(���ޱ�����)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        8) ��Ÿ �����ڻ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        9) ���޺��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ���޺��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        10) ������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        11) �����ޱ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. �����ޱ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               ���԰����ޱ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        12) ���޹��μ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ���޹��μ�/�߰�����</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               ���޹��μ�/���ڼҵ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        13) ���޼���</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ���޼���</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        14) �ΰ�����ޱ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. �ΰ�����ޱ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>             �̿����μ��ڻ�(����)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. �̿����μ��ڻ�(����)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        15) �ڱ��ä</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               �ڱ��ä</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        16) ��Ÿ�����ڻ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ��Ÿ�����ڻ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>      2. ����ڻ�</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        1) ��ǰ</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ��ǰ</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. ��ǰ ����ڻ�������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. ��ǰ���� Ÿ�������δ�ü</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. Ÿ�������� ��ǰ���δ�ü��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        2) ��ǰ</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. ��ǰ</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. ��ǰ ����ڻ�������</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. Ÿ�������� ��ǰ���δ�ü��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. ��ǰ���� Ÿ�������δ�ü��</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026105,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021885