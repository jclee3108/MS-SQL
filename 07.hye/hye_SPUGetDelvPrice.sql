IF OBJECT_ID('hye_SPUGetDelvPrice') IS NOT NULL 
    DROP PROC hye_SPUGetDelvPrice
GO 

-- v2016.12.19 

-- ���Ŵܰ���������(���Ŵܰ����_hye ����) by����õ 
/************************************************************
��  �� - �����԰�(��ǰ)�ǿ� �ش��ϴ� ���Ŵܰ� ��������
�ۼ��� - 2010�� 04�� 05�� 
�ۼ��� - ������
������ - 2010�� 6�� 24��
������ - ����
************************************************************/
CREATE PROC dbo.hye_SPUGetDelvPrice
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    DECLARE @Count        INT,
            @Seq          INT,
            @MessageType  INT,
            @Status       INT,
            @GetPriceType INT,
            @MaxRow		  INT,
            @Results      NVARCHAR(250)

    -- ���� ����Ÿ ��� ����
    CREATE TABLE #TPUGetDelvPrice (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUGetDelvPrice'     
    IF @@ERROR <> 0 RETURN    
    
	-- �ŷ�ó, �ܰ� ������Ʈ
	UPDATE #TPUGetDelvPrice
	   SET CustSeq	=	B.CustSeq,
		   CurrSeq	=   B.CurrSeq
	  FROM #TPUGetDelvPrice	AS A
		   JOIN _TPUDelv	AS B ON A.DelvSeq = B.DelvSeq
	 WHERE B.CompanySeq = @CompanySeq
	   AND A.CustSeq IS NULL AND A.CurrSeq IS NULL		   
	-- ������ ��������(�ֱ� ���Ŵܰ� ��� ����)    
	EXEC dbo._SCOMEnv @CompanySeq,6501,@UserSeq,@@PROCID,@GetPriceType OUTPUT  
	
    IF @GetPriceType = '6072001'  -- ���Ŵܰ���Ͽ��� ��������  
	BEGIN
		-- �԰����Ϳ� �ش��ϴ� �ŷ�ó�� �԰��ϱ��شܰ�.
		UPDATE A
		   SET Price = P.Price
		  FROM #TPUGetDelvPrice         AS A 
			JOIN _TPUDelvIn             AS D WITH(NOLOCK) ON A.DelvInSeq  = D.DelvInSeq
														 AND D.CompanySeq = @CompanySeq
			JOIN _TPUBASEBuyPriceItem   AS P WITH(NOLOCK) ON A.ItemSeq    = P.ItemSeq
														 AND D.DelvInDate BETWEEN P.StartDate AND P.EndDate
														 AND D.CustSeq    = P.CustSeq
														 AND P.CompanySeq = @CompanySeq
		-- �԰���� ���� ���� ��ǰ�� �������� 
		UPDATE A
		   SET Price = P.Price
		  FROM #TPUGetDelvPrice         AS A 
			JOIN _TPUDelv               AS D WITH(NOLOCK) ON A.DelvSeq    = D.DelvSeq
														 AND D.CompanySeq = @CompanySeq
			JOIN _TPUBASEBuyPriceItem   AS P WITH(NOLOCK) ON A.ItemSeq    = P.ItemSeq
														 AND D.DelvDate   BETWEEN P.StartDate AND P.EndDate
														 AND D.CustSeq    = P.CustSeq
														 AND P.CompanySeq = @CompanySeq
		 WHERE ISNULL(DelvInSeq,0) = 0 


        -- ���Ŵܰ����_hye ���� by����õ 
        DECLARE @SKCustSeq INT 
        SELECT @SKCustSeq = (SELECT TOP 1 EnvValue FROM hye_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 5) 


        UPDATE A
            SET Price = B.YSSPrice 
        from #TPUGetDelvPrice AS A 
        JOIN hye_TPUBaseBuyPriceItem AS B ON ( B.CompanySeq = @CompanySeq 
                                            AND B.ItemSeq = A.ItemSeq 
                                            AND B.UnitSeq = A.UnitSeq 
                                            AND B.CurrSeq = A.CurrSeq 
                                            AND B.UMDVGroupSeq = A.UMDVGroupSeq 
                                            ) 
        LEFT OUTER JOIN _TDAItemPurchase  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
        LEFT OUTER JOIN _TDAItemUserDefine AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = B.ItemSeq AND D.MngSerl = 1000005 )     
        WHERE (CASE WHEN ISNULL(A.DelvInDate,'') = '' THEN A.DelvDate ELSE A.DelvInDate END) BETWEEN B.SrtDate AND B.EndDate 
            AND C.PurCustSeq = @SKCustSeq 
            AND ISNULL(C.PurCustSeq,0) <> 0 
            AND (D.MngValText = '1' OR D.MngValText = 'True')
        -- ���Ŵܰ����_hye ����, END 
    
	END
	ELSE IF @GetPriceType = '6072002'	-- �ֱٰŷ�ó�ܰ� ��������(����)
	BEGIN  
		SELECT @MaxRow = MAX(IDX_NO) FROM #TPUGetDelvPrice  
		SELECT @Count  = 1  
		WHILE ( 1 = 1)  
		BEGIN  
			IF @Count > @MaxRow BREAK  
			UPDATE #TPUGetDelvPrice  
			   SET Price = B.Price  
			  FROM #TPUGetDelvPrice	  AS A  
				   JOIN _TPUORDPOItem AS B ON A.ItemSeq    = B.ItemSeq  
				   JOIN _TPUORDPO	  AS C ON B.CompanySeq = C.CompanySeq   
										  AND B.POSeq      = C.POSeq  
					  WHERE B.CompanySeq = @CompanySeq         
						AND A.IDX_NO  = @Count       
						AND A.CurrSeq = C.CurrSeq  
						AND A.CustSeq = C.CustSeq  
						AND C.PONo IN (SELECT TOP 1 ISNULL(MAX(B.PONo), 0) FROM _TPUORDPOItem		  AS A  
																				 JOIN _TPUORDPO		  AS B ON A.CompanySeq = B.CompanySeq  
																									 	  AND A.POSeq   = B.POSeq  
																				 JOIN #TPUGetDelvPrice AS C ON A.ItemSeq  = C.ItemSeq  
																		   WHERE A.CompanySeq = @CompanySeq  
																			 AND C.IDX_NO  = @Count  
																			 AND B.CurrSeq = C.CurrSeq  
																			 AND B.CustSeq = C.CustSeq
																			 AND A.Price <> 0)  
			SELECT @Count = @Count + 1  
		END  
	END  
	ELSE IF @GetPriceType = '6072003'	-- �ֱٰŷ�ó�ܰ� ��������(��ǰ)
	BEGIN  
		SELECT @MaxRow = MAX(IDX_NO) FROM #TPUGetDelvPrice  
		SELECT @Count  = 1  
		WHILE ( 1 = 1)  
		BEGIN  
			IF @Count > @MaxRow BREAK  
			UPDATE #TPUGetDelvPrice  
			   SET Price = B.Price  
			  FROM #TPUGetDelvPrice	  AS A  
				   JOIN _TPUDelvItem AS B ON A.ItemSeq    = B.ItemSeq  
				   JOIN _TPUDelv	  AS C ON B.CompanySeq = C.CompanySeq   
										  AND B.DelvSeq    = C.DelvSeq  
					  WHERE B.CompanySeq = @CompanySeq         
						AND A.IDX_NO  = @Count       
						AND A.CurrSeq = C.CurrSeq  
						AND A.CustSeq = C.CustSeq  
						AND C.DelvNo IN (SELECT TOP 1 ISNULL(MAX(B.DelvNo), 0) FROM _TPUDelvItem	   AS A  
																			 	  JOIN _TPUDelv		   AS B ON A.CompanySeq = B.CompanySeq  
																									 	   AND A.DelvSeq    = B.DelvSeq  
																				 JOIN #TPUGetDelvPrice AS C ON A.ItemSeq	= C.ItemSeq  
																		   WHERE A.CompanySeq = @CompanySeq  
																			 AND C.IDX_NO  = @Count  
																			 AND B.CurrSeq = C.CurrSeq  
																			 AND B.CustSeq = C.CustSeq
																			 AND A.Price <> 0)  
			SELECT @Count = @Count + 1  
		END  
	END  
    SELECT * FROM #TPUGetDelvPrice   
    RETURN    
GO
begin tran 
exec hye_SPUGetDelvPrice @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMDVGroupSeq>1013554001</UMDVGroupSeq>
    <DelvDate>20161219</DelvDate>
    <DelvSeq>144</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <DelvInSeq>0</DelvInSeq>
    <DelvInSerl>0</DelvInSerl>
    <ItemSeq>18</ItemSeq>
    <Price>555555</Price>
    <CurrSeq>3</CurrSeq>
    <DelvInDate />
    <CustSeq>24</CustSeq>
    <UnitSeq>1</UnitSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMDVGroupSeq>1013554001</UMDVGroupSeq>
    <DelvDate>20161219</DelvDate>
    <DelvSeq>145</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <DelvInSeq>0</DelvInSeq>
    <DelvInSerl>0</DelvInSerl>
    <ItemSeq>18</ItemSeq>
    <Price>20000</Price>
    <CurrSeq>3</CurrSeq>
    <DelvInDate />
    <CustSeq>24</CustSeq>
    <UnitSeq>1</UnitSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730152,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730049
rollback 