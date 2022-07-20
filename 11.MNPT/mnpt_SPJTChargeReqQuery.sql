IF OBJECT_ID('mnpt_SPJTChargeReqQuery') IS NOT NULL
    DROP PROC mnpt_SPJTChargeReqQuery
GO 
/************************************************************
 ��  ��		- û�������ȸ(����)_mnpt
 �ۼ���		- 2017�� 9�� 08��  
 �ۼ���		- ����
 ��������	- 
 ************************************************************/
 CREATE PROC mnpt_SPJTChargeReqQuery  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS
	DECLARE @ChargeDate			NCHAR(6),
			@UMContractType		INT,
			@IFShipCode			NVARCHAR(100),
			@ShipYear			NVARCHAR(100),
			@ShipSerl			NVARCHAR(100),
			@BizUnit			INT,
			@UMChargeType		INT,
			@ShipSeq			INT,
			@PJTName			NVARCHAR(100),
			@PJTTypeName		NVARCHAR(100),
			@CustName			NVARCHAR(100),
			@SMExpKind			INT,
			@UMExampleKind		INT,
			@UMChargeCreate		INT,
			@UMChargeComplete	INT,
			@PJTNo				NVARCHAR(100),
			@ContractName		NVARCHAR(100),
			@ContractNo			NVARCHAR(100),
			@OutFrDate			NCHAR(8),
			@OutToDate			NCHAR(8),
			@ChargeFrDate		NCHAR(6),
			@ChargeToDate		NCHAR(6)
	SELECT @ChargeDate			= ISNULL(ChargeDate, ''),
		   @UMContractType		= ISNULL(UMContractType, 0),
		   @IFShipCode			= ISNULL(IFShipCode, ''),
		   @ShipYear			= ISNULL(ShipYear, ''),
		   @ShipSerl			= ISNULL(ShipSerl, ''),
		   @BizUnit				= ISNULL(BizUnit, 0),
		   @UMChargeType		= ISNULL(UMChargeType, 0),
		   @ShipSeq				= ISNULL(ShipSeq, 0),
		   @PJTName				= ISNULL(PJTName, ''),
		   @PJTTypeName			= ISNULL(PJTTypeName, ''),
		   @CustName			= ISNULL(CustName, ''),
		   @SMExpKind			= ISNULL(SMExpKind, 0),
		   @UMExampleKind		= ISNULL(UMExampleKind, 0),
		   @UMChargeCreate		= ISNULL(UMChargeCreate, 0),
		   @UMChargeComplete	= ISNULL(UMChargeComplete, 0),
		   @PJTNo				= ISNULL(PJTNo, 0),
		   @ContractName		= ISNULL(ContractName, 0),
		   @ContractNo			= ISNULL(ContractNo	, 0),
		   @OutFrDate			= ISNULL(OutFrDate, ''),
		   @OutToDate			= ISNULL(OutToDate, ''),
		   @ChargeFrDate		= ISNULL(ChargeFrDate, ''),
		   @ChargeToDate		= ISNULL(ChargeToDate, '')
	  FROM #BIZ_IN_DataBlock1	
	  

	CREATE TABLE #tmpContract (
		BizUnitName				NVARCHAR(100),
		ContractName			NVARCHAR(100),
		ContractNo				NVARCHAR(100),
		UMContractTypeName		NVARCHAR(100),
		UMContractKindName		NVARCHAR(100),
		PJTTypeName				NVARCHAR(100),
		PJTNo					NVARCHAR(100),
		PJTName					NVARCHAR(100),
		CustName				NVARCHAR(100),
		UMChargeTypeName		NVARCHAR(100),
		SMExpKindName			NVARCHAR(100),
		ContractFrDate			NCHAR(8),
		ContractToDate			NCHAR(8),
		IsFakeContract			NCHAR(1),
		IsContractSideFee		NCHAR(1),
		IsContractLoadFee		NCHAR(1),
		IsContractStorageFee	NCHAR(1),
		ContractFrDateYM		NCHAR(6),
		ContractToDateYM		NCHAR(6),
		ContractSeq				INT,
		PJTSeq					INT,
		UMWorkType				INT,
		IsShip					NCHAR(1),
		ChargeDate				NCHAR(8)
	)
	/*
		��ȸ������ ������ư �ּ�
		��������ϱ��غ���(��������) : û�������� �ɸ��� ��൥���� ��ȸ (�����������)
		������κ���(��������):��� ����� �����ֵ�, û������ Fr ~ To�� �ش��ϴ� �����͸� ������ �ѷ��ֱ�
		�۾����غ���: �۾������� �������� û�������� �ɸ��� �۾����ִ� ��൥���ͺ����ֱ�.
	*/

	--���� û�������� ���..
	DECLARE @ChargeFrDate2	NCHAR(6)
	SELECT @ChargeFrDate2 = @ChargeFrDate
	WHILE(@ChargeFrDate2 <= @ChargeToDate)
	BEGIN
		INSERT INTO #tmpContract (
			BizUnitName,			ContractName,				ContractNo,					UMContractTypeName,
			UMContractKindName,		PJTTypeName,				PJTNo,						PJTName,
			CustName,				UMChargeTypeName,			SMExpKindName,				ContractFrDate,
			ContractToDate,			IsFakeContract,				IsContractSideFee,			IsContractLoadFee,
			IsContractStorageFee,	ContractFrDateYM,			ContractToDateYM,			ContractSeq,
			PJTSeq,					UMWorkType,					IsShip,
			ChargeDate
		)
		SELECT
			D.BizUnitName,			A.ContractName,				A.ContractNo,				E.MinorName,
			F.MinorName,			G.PJTTypeName,				C.PJTNo,					C.PJTName,
			H.CustName,				J.MinorName,				I.MinorName,				A.ContractFrDate,
			A.ContractToDate,		A.IsFakeContract,			'0',						'0',
			'0',					LEFT(A.ContractFrDate, 6),	LEFT(A.ContractToDate, 6),	A.ContractSeq,
			C.PJTSeq,				0,							CASE WHEN ISNULL(K.ValueText, 0) = 0 THEN '0' ELSE '1' END,
			@ChargeFrDate2
		  FROM mnpt_TPJTContract AS A WITH(NOLOCK)		
			   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
					   ON B.CompanySeq	= A.CompanySeq
					  AND B.ContractSeq	= A.ContractSeq
			   INNER JOIN _TPJTProject AS C WITH(NOLOCK)
					   ON C.CompanySeq	= B.CompanySeq
					  AND C.PJTseq		= B.PJTSeq
			   LEFT  JOIN _TDABizUnit AS D WITH(NOLOCK)
					   ON D.CompanySeq	= A.CompanySeq
					  AND D.BizUnit		= A.BizUnit
			   LEFT  JOIN _TDAUMinor AS E WITH(NOLOCK)
					   ON E.CompanySeq	= A.CompanySeq
					  AND E.Minorseq	= A.UMContractType
			   LEFT  JOIN _TDAUMinor AS F WITH(NOLOCK)
					   ON F.CompanySeq	= A.CompanySeq
					  AND F.Minorseq	= A.UMContractKind
			   LEFT  JOIN _TPJTType AS G WITH(NOLOCK)
					   ON G.CompanySeq	= C.CompanySeq
					  AND G.PJTTypeSeq	= C.PJTTypeSeq
			   LEFT  JOIN _TDACust AS H WITH(NOLOCK)
					   ON H.CompanySeq	= A.CompanySeq
					  AND H.CustSeq		= A.CustSeq
			   LEFT  JOIN _TDASMinor AS I WITH(NOLOCK)
					   ON I.CompanySeq	= A.CompanySeq
					  AND I.MinorSeq	= A.SMExpKind
			   LEFT  JOIN _TDAUMinor AS J WITH(NOLOCK)
					   ON J.CompanySeq	= A.CompanySeq
					  AND J.Minorseq	= A.UMChargeType
			   LEFT  JOIN _TDAUMinorValue AS K WITH(NOLOCK)
					   ON K.CompanySeq	= A.CompanySeq
					  AND K.MinorSeq	= A.UMChargeType
					  AND K.Serl		= 1000001
					  AND K.ValueText	= '1'
			   LEFT  JOIN _TDAUMinorValue AS L WITH(NOLOCK)
					   ON L.CompanySeq	= A.CompanySeq
					  AND L.MinorSeq	= A.UMContractKind
					  AND L.Serl		= 1000002
					  AND L.MajorSeq	= 1015778
		 WHERE A.CompanySeq					= @CompanySeq
		   AND B.SourcePJTSeq				= 0
		   AND A.IsStop						= '0'
		   AND A.IsComplete					= '0'
		   AND ISNULL(L.ValueText, '0')		= '0'
		   AND (@BizUnit		= 0 OR A.BizUnit		= @BizUnit)
		   AND (@UMContractType	= 0 OR A.UMContractType	= @UMContractType)
		   AND (@UMChargeType	= 0 OR A.UMChargeType	= @UMChargeType)
		   AND (@SMExpKind		= 0 OR A.SMExpKind		= @SMExpKind)
		   AND @ChargeFrDate2 BETWEEN CASE WHEN @UMExampleKind = 1015856001 THEN LEFT(A.ContractFrDate, 6)
										   ELSE @ChargeFrDate2
										   END
								  AND CASE WHEN @UMExampleKind = 1015856001 THEN LEFT(A.ContractToDate, 6)
										   ELSE @ChargeFrDate2
										   END

		SELECT @ChargeFrDate2 = CONVERT(NCHAR(6),DATEADD(MM, +1, CONVERT(DATETIME, @ChargeFrDate2 + '01')) , 112)
	END
	--���ֿ��ȿ������ε���ο� ��ϵǾ��ִ� ������Ʈ�� �ȳ����� ����.
	DELETE #tmpContract
	  FROM #tmpContract AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM mnpt_TPJTEEExcelUploadMapping
					 WHERE PJTSeq	= A.PJTSeq
				)
	--ȭ�¿� ������ƴ��� ��ϵ� ������Ʈ�� �Ⱥ��̰� ����.
	DELETE #tmpContract
	  FROM #tmpContract AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM _TPJTProject AS Z WITH(NOLOCK)
						   LEFT  JOIN _TPJTType AS Y WITH(NOLOCK)
								   ON Y.CompanySeq	= Z.CompanySeq
								  AND Y.PJTTypeSeq	= Z.PJTTypeSeq
					 WHERE Z.CompanySeq			= @CompanySeq
					   AND Z.PJTSeq				= A.PJTSeq
					   AND Y.SMSalesRecognize = 7002005
				)
	
	----��������ϱ��غ���(��������) üũ�� û����� ���Ե��� �ʴ� ������Ʈ ����
	--����, û�������� ����鼭 û������ ������ �Ȱɰ� ������κ��⸦ �ϸ�
	--������ ���Ǻ��� û�������� ��� �����͸� ��ƾ� �ϱ⶧���� ���̺� FullScan�� ������..
	--IF @UMExampleKind	= 1015856001
	--BEGIN
	--	DELETE #tmpContract
	--	  FROM #tmpContract
	--	 WHERE (ContractFrDateYM > @ChargeDate OR ContractToDateYM < @ChargeDate)
	--END
	DECLARE @EnvSideFee			INT,
			@EnvLoadFee			INT,
			@EnvStorageFee		INT
	--���ȷ� ǰ���ߺз�
	SELECT @EnvSideFee	= EnvValue
	  FROM mnpt_TCOMEnv 
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 7
	--�Ͽ��� ǰ���ߺз�
	SELECT @EnvLoadFee	= EnvValue
	  FROM mnpt_TCOMEnv 
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 8
	--������ ǰ���ߺз�
	SELECT @EnvStorageFee	= EnvValue
	  FROM mnpt_TCOMEnv			
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 9
	--����� ���ȷ�, �Ͽ���, ������ ���� Insert
	CREATE TABLE #tmpItemLClass(
		ContractSeq				INT,
		IsContractSideFee		NCHAR(1),
		IsContractLoadFee		NCHAR(1),
		IsContractStorageFee	NCHAR(1)
	)
	INSERT INTO #tmpItemLClass (
		ContractSeq,
		IsContractSideFee,
		IsContractLoadFee,
		IsContractStorageFee
	)
	SELECT
		A.ContractSeq,
		CASE WHEN ISNULL(D.IsContractSideFee, 0) = 0 THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(E.IsContractLoadFee, 0) = 0 THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(F.IsContractStorageFee, 0) = 0 THEN '0' ELSE '1' END
	  FROM mnpt_TPJTContract AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.ContractSeq	= A.ContractSeq
		   INNER JOIN _TPJTProject AS C WITH(NOLOCK)
				   ON C.CompanySeq	= B.CompanySeq
				  AND C.PJTSeq		= B.PJTSeq
		   LEFT  JOIN (
						SELECT E.ContractSeq, COUNT(1) AS IsContractSideFee
						  FROM _TPJTProjectDelivery AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
								LEFT  JOIN mnpt_TPJTProject AS D WITH(NOLOCK)
									    ON D.CompanySeq	= A.CompanySeq
									   AND D.PJTSeq		= A.PJTSeq
							    LEFT  JOIN mnpt_TPJTContract AS E WITH(NOLOCK)
										ON E.CompanySeq		= D.CompanySeq
									   AND E.ContractSeq	= D.ContractSeq
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvSideFee
							AND D.SourcePJTSeq		= 0
						  GROUP BY E.ContractSeq
					) AS D 
				   ON D.ContractSeq	= A.ContractSeq
		   LEFT  JOIN (
						SELECT E.ContractSeq, COUNT(1) AS IsContractLoadFee
						  FROM _TPJTProjectDelivery AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
								LEFT  JOIN mnpt_TPJTProject AS D WITH(NOLOCK)
									    ON D.CompanySeq	= A.CompanySeq
									   AND D.PJTSeq		= A.PJTSeq
							    LEFT  JOIN mnpt_TPJTContract AS E WITH(NOLOCK)
										ON E.CompanySeq		= D.CompanySeq
									   AND E.ContractSeq	= D.ContractSeq
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvLoadFee
							AND D.SourcePJTSeq		= 0
						  GROUP BY E.ContractSeq
					) AS E 
				   ON E.ContractSeq	= A.ContractSeq
		   LEFT  JOIN (
						SELECT E.ContractSeq, COUNT(1) AS IsContractStorageFee
						  FROM _TPJTProjectDelivery AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
								LEFT  JOIN mnpt_TPJTProject AS D WITH(NOLOCK)
									    ON D.CompanySeq	= A.CompanySeq
									   AND D.PJTSeq		= A.PJTSeq
							    LEFT  JOIN mnpt_TPJTContract AS E WITH(NOLOCK)
										ON E.CompanySeq		= D.CompanySeq
									   AND E.ContractSeq	= D.ContractSeq
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvStorageFee
							AND D.SourcePJTSeq		= 0
						  GROUP BY E.ContractSeq
					) AS F 
				   ON F.ContractSeq	= A.ContractSeq
	 WHERE A.CompanySeq		= @CompanySeq
	   AND B.SourcePJTSeq	= 0				--SourcePJTSeq = 0 : ��õ������Ʈ.
	   AND EXISTS (
					SELECT 1
					  FROM #tmpContract
					 WHERE ContractSeq	= A.ContractSeq
				)
	 GROUP BY A.ContractSeq,
			  CASE WHEN ISNULL(D.IsContractSideFee, 0) = 0 THEN '0' ELSE '1' END,
			  CASE WHEN ISNULL(E.IsContractLoadFee, 0) = 0 THEN '0' ELSE '1' END,
			  CASE WHEN ISNULL(F.IsContractStorageFee, 0) = 0 THEN '0' ELSE '1' END

	--����� ���ȷ�, �Ͽ���, ������ ���� Update
	UPDATE #tmpContract
	   SET IsContractSideFee	= ISNULL(B.IsContractSideFee, '0'),
		   IsContractLoadFee	= ISNULL(B.IsContractLoadFee, '0'),
		   IsContractStorageFee	= ISNULL(B.IsContractStorageFee, '0')
	  FROM #tmpContract AS A
		   LEFT  JOIN #tmpItemLClass AS B
				   ON B.ContractSeq		= A.ContractSeq


	--/************************************************************************
	--����Է��� û���׸�-�۾��׸� ���ο��� û���׸��� �ߺз��� ȯ�漳��(�߰����߿�)_mnpt��
	--�Ͽ��� û���׸� �ߺз��̸鼭, û���ݾ׻����� üũ���Ǿ������鼭, ����ù��°�� ��ϵ�
	--�۾��׸�������..
	--************************************************************************/
	CREATE TABLE #tmpWorktype(
		PJTSeq			INT,
		UMWorkType		INT
	)
	INSERT INTO #tmpWorktype
	SELECT A.PJTSeq, A.UMWorkType
	  FROM mnpt_TPJTProjectMapping AS A WITH(NOLOCK)
		   INNER JOIN (
						SELECT PJTSeq, MIN(MappingSerl) AS MappingSerl
						  FROM mnpt_TPJTProjectMapping AS A WITH(NOLOCK)
							   INNER JOIN _TDAItemClass AS B WITH(NOLOCK)
									   ON B.CompanySeq		= A.CompanySeq
									  AND B.ItemSeq			= A.ItemSeq
									  AND B.UMajorItemClass	IN (2001, 2004)
							   INNER JOIN _VDAItemClass AS C 
								       ON C.CompanySeq		= B.CompanySeq
									  AND C.ItemClassSSeq	= B.UMItemClass
						  WHERE A.CompanySeq	= @CompanySeq
						    AND C.ItemClassMSeq	= @EnvLoadFee
							AND A.IsAmt			= '1'
						  GROUP BY PJTSeq
					) AS B
				  ON B.PJTSeq		= A.PJTSeq
				 AND B.MappingSerl	= A.MappingSerl
	 WHERE A.CompanySeq	= @CompanySeq
	   AND EXISTS (
					SELECT 1
					  FROM #tmpContract
					 WHERE PJTseq	= A.PJTseq
				)
	--������Ʈ�� û���׸��� ��ǥ �۾��׸� Mapping ������Ʈ.
	UPDATE #tmpContract
	   SET UMWorkType	= B.UMWorkType
	  FROM #tmpContract AS A
		   INNER JOIN #tmpWorktype AS B
				   ON B.PJTseq	= A.PJTSeq
	--�۾����� ��� ���ϱ�.
	CREATE TABLE #tmpShipDetail (
		ContractSeq		INT,
		PJTSeq			INT,
		WorkReportSeq	INT,
		ShipSeq			INT,
		ShipSerl		INT,
		IsShip			NCHAR(1),		
		WorkDateYM		NCHAR(6)
	)	
	INSERT INTO #tmpShipDetail (
		ContractSeq,		PJTSeq,			WorkReportSeq,
		ShipSeq,			ShipSerl,		IsShip,
		WorkDateYM
	)
	SELECT
		C.ContractSeq,		A.PJTSeq,		A.WorkReportSeq,
		A.ShipSeq,			A.ShipSerl,		CASE WHEN A.ShipSeq <> 0 THEN '1' ELSE '0' END,
		LEFT(A.WorkDate, 6)
	  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.PJTSeq		= A.PJTSeq
		   INNER JOIN mnpt_TPJTContract AS C WITH(NOLOCK)
				   ON C.CompanySeq	= B.CompanySeq
				  AND C.ContractSeq	= B.ContractSeq
	 WHERE A.CompanySeq		= @CompanySeq
	   AND B.SourcePJTSeq	= 0
	   AND A.IsCfm			= '1'
	   AND EXISTS (
					SELECT 1
					  FROM #tmpContract
					 WHERE PJTSeq	= A.PJTSeq
				)

	CREATE TABLE #tmpShipResult (
		ContractSeq			INT,
		PJTSeq				NVARCHAR(100),
		WorkReportSeq		NVARCHAR(500),
		ShipSeq				INT,
		ShipSerl			INT,
		IsShip				NCHAR(1),
		IFShipCode			NVARCHAR(100),
		ShipYear			NVARCHAR(100),
		ShipSerl2			NVARCHAR(100),
		FullShipName		NVARCHAR(100),
		EnShipName			NVARCHAR(100),
		ShipCnt				INT,
		InDateTime			NCHAR(8),
		OutDateTime			NCHAR(8),
		ApproachDateTime	INT,
		WorkDate			INT,
		WorkQty				DECIMAL(19, 5),
		TodayMTWeight		DECIMAL(19, 5),
		TodayCBMWeight		DECIMAL(19, 5),
		WorkCnt				INT,
		PJTName				NVARCHAR(100),
		PJTNo				NVARCHAR(100),
		PJTTypeName			NVARCHAR(100),
		ChargeDate			NCHAR(6)		--���������ִ°��� ���׿�. ���°��� û������.
	)

	--�������� �����ϴ� ������, �������Ǻ��� �����ֵ�, ��� ���������ʹ� ���� ������� Sum������
	--IsShip = '1' : �������� �����ϴ� ����.
	IF EXISTS (SELECT 1 FROM #tmpShipDetail WHERE IsShip = '1' )
	BEGIN
		INSERT INTO #tmpShipResult (
			ContractSeq,
			PJTSeq,			
			WorkReportSeq,		
			ShipSeq,			
			ShipSerl,
			IsShip,		
			IFShipCode,
			ShipYear,
			ShipSerl2,
			FullShipName,		
			EnShipName,			
			ShipCnt,
			InDateTime,		
			OutDateTime,		
			ApproachDateTime,
			WorkDate,
			WorkQty,
			TodayMTWeight,
			TodayCBMWeight,
			WorkCnt,
			PJTName,
			PJTNo,
			PJTTypeName,
			ChargeDate
		)
		SELECT  
			C.ContractSeq,
		    C.PJTSeq					AS PJTSeq,
		    CASE WHEN C.WorkReportSeq IS NULL OR LEN(C.WorkReportSeq) = 0 THEN '' 
				 ELSE  SUBSTRING(C.WorkReportSeq, 1,  LEN(C.WorkReportSeq) -1 ) END		AS WorkReportSeq,
			A.ShipSeq,
			A.ShipSerl,
			C.IsShip,
		    A.IFShipCode, 
		    LEFT(A.ShipSerlNo, 4),
		    RIGHT(A.ShipSerlNo, 3),
			
			A.IFShipCode + '-' + LEFT(A.ShipSerlNo, 4) + '-' + RIGHT(A.ShipSerlNo, 3)  AS FullShipName,	--������
			B.EnShipName,										--�𼱸�
			1,													--������Ƚ��(�������ϰ��� ������ 1�̴�, �𼱺��� 1�Ǿ� �����ֱ� ������)
			LEFT(A.InDateTime, 8)		AS InDateTime,			--������
			LEFT(A.OutDateTime, 8)		AS OutDateTime,			--������
			A.DiffApproachTime			AS DiffApproachTime,	--�۾��ð�
			C.WorkDatecnt				AS WorkDatecnt,			--�۾��ϼ�
			C.WorkQty					AS WorkQty,				--����
			C.TodayMTWeight				AS TodayMTWeight,		--�۾���(MT)
			C.TodayCBMWeight			AS TodayCBMWeight,		--�۾���(CBM)
			C.WorkCnt					AS WorkCnt,				--�۾��׸��
			C.PJTName					AS PJTName,
			C.PJTNo						AS PJTNo,
			C.PJTTypeName				AS PJTTypeName,
			LEFT(A.OutDateTime, 6)
		  FROM  (
							SELECT A.ContractSeq, 
								   A.ShipSeq, 
								   A.ShipSerl,
								   A.IsShip,
								   B.WorkDatecnt,
								   C.WorkQty,
								   C.TodayMTWeight,
								   C.TodayCBMWeight,
								   D.WorkCnt,
								   E.WorkReportSeq,
								   F.PJTSeq,
								   F.PJTName,
								   F.PJTNo,
								   G.PJTTypeName
							  FROM #tmpShipDetail AS A
								   --���������� �۾��ϼ� ���ϱ�
								   --�������� �������� �۾��� �־ �ش� �۾����� 1�� �ľ��ϱ� ������ Union���� �ߺ��� �����ϰ�
								   --Count�Ѵ�.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, COUNT(1) AS WorkDateCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq
											) AS B 
										   ON B.ContractSeq		= A.ContractSeq
										  AND B.ShipSeq			= A.ShipSeq
										  AND B.ShipSerl		= A.ShipSerl
										  AND B.PJTSeq			= A.PJTSeq
								  LEFT  JOIN (
												--����Է��� û���׸� -�۾��׸� ���ο� ���ε� �۾��� ������������.
												SELECT B.ContractSeq,
													   A.ShipSeq,
													   A.ShipSerl,
													   A.PJTSeq,
													   SUM(A.TodayQty)			AS WorkQty,
													   SUM(A.TodayMTWeight)		AS TodayMTWeight,
													   SUM(A.TodayCBMWeight)	AS TodayCBMWeight
												  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
													   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
															   ON B.CompanySeq	= A.CompanySeq
															  AND B.PJTSeq		= A.PJTSeq
													   INNER JOIN #tmpWorktype AS C
															   ON C.PJTSeq		= A.PJTSeq
															  AND C.UMWorkType	= A.UMWorkType
												 WHERE A.CompanySeq	= @CompanySeq
												   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																SELECT 1
																  FROM #tmpShipDetail 
																  WHERE WorkReportSeq	= A.WorkReportSeq
																   AND IsShip			= '1'
															)
												 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq
											) AS C 
										   ON C.ContractSeq	= A.ContractSeq
										  AND C.ShipSeq		= A.ShipSeq
										  AND C.ShipSerl	= A.ShipSerl
										  AND C.PJTSEq		= A.PJTSeq
								   --���������� �۾��׸�� ���ϱ�
								   --�ٸ����� �������� �۾��� �־ �ش� �۾��׸��� 1�� ���������ϱ� ������ Union���� �ߺ��� �����ϰ�
								   --Count�Ѵ�.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, COUNT(1) AS WorkCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSEq
											) AS D 
										   ON D.ContractSeq	= A.ContractSeq
										  AND D.ShipSeq		= A.ShipSeq
										  AND D.ShipSerl	= A.ShipSerl
										  AND D.PJTSeq		= A.PJTSeq
								   --�ϳ��� ��û���ǿ� � �۾����������ڵ尡 �ɷ��ִ��� ','�� �����Ͽ� �����ֱ�.
								   LEFT  JOIN (
												SELECT ContractSeq, ShipSeq, ShipSerl, PJTSeq,
														(
															SELECT CONVERT(NVARCHAR(100), WorkReportSeq) + ','
															  FROM #tmpShipDetail
															 WHERE ShipSeq		= A.ShipSeq
															   AND ShipSerl		= A.ShipSerl
															   AND ContractSeq	= A.ContractSeq
															   AND PJTSeq		= A.PJTSeq
															 ORDER BY WorkReportSeq for xml path('')
															) AS WorkReportSeq
												  FROM #tmpShipDetail AS A
												 WHERE A.IsSHip	= '1'
												 GROUP BY ContractSeq, ShipSeq, ShipSerl, PJTSeq
											) AS E
										   ON E.ContractSeq	= A.ContractSeq
										  AND E.ShipSeq		= A.ShipSeq
										  AND E.ShipSerl	= A.ShipSerl
										  AND E.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTProject AS F WITH(NOLOCK)
										   ON F.CompanySeq	= @CompanySeq
										  AND F.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTType AS G WITH(NOLOCK)
										   ON G.CompanySeq	= F.CompanySeq
										  AND G.PJTTypeSeq	= F.PJTTypeSeq
							 WHERE IsShip	= '1'	--��û���ϰ��
							 GROUP BY A.ContractSeq,	A.ShipSeq,				A.ShipSerl,			B.WorkDatecnt, 
									  C.WorkQty,		C.TodayMTWeight,		C.TodayCBMWeight,	D.WorkCnt,	 
									  E.WorkReportSeq,	F.PJTSeq,				F.PJTName,			G.PJTTypeName,	
									  A.IsShip,			F.PJTNo
						) AS C 
			   LEFT  JOIN MNPT_TPJTShipDetail AS A WITH(NOLOCK)
					   ON A.ShipSeq		= C.ShipSeq
					  AND A.ShipSerl	= C.ShipSerl
			   LEFT  JOIN MNPT_TPJTShipMaster AS B WITH(NOLOCK)
					   ON B.CompanySeq	= A.CompanySeq
					  AND B.ShipSeq		= A.ShipSeq
	     WHERE EXISTS (
						SELECT 1
						  FROM #tmpShipDetail
						 WHERE ShipSeq	= C.ShipSeq
						   AND ShipSerl	= C.ShipSerl
						   AND IsShip	= '1'
					)
		   AND LEFT(A.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate
	END
	--���� ���°��� �ش� û������ �´� �����͸� �����ؼ� �����ֱ�.
	--IsShip = '0' : �������� ���� ����..
	IF EXISTS (SELECT 1 FROM #tmpShipDetail WHERE IsShip = '0')
	BEGIN
		INSERT INTO #tmpShipResult (
			ContractSeq,
			PJTSeq,			
			WorkReportSeq,		
			ShipSeq,			
			ShipSerl,
			IsShip,		
			IFShipCode,
			ShipYear,
			ShipSerl2,
			FullShipName,		
			EnShipName,			
			ShipCnt,
			InDateTime,		
			OutDateTime,		
			ApproachDateTime,
			WorkDate,
			WorkQty,
			TodayMTWeight,
			TodayCBMWeight,
			WorkCnt,
			PJTName,
			PJTNo,
			PJTTypeName,
			ChargeDate
		)
		SELECT  
			C.ContractSeq,
		    C.PJTSeq		AS PJTSeq,
		    CASE WHEN C.WorkReportSeq IS NULL OR LEN(C.WorkReportSeq) = 0 THEN '' 
				 ELSE  SUBSTRING(C.WorkReportSeq, 1,  LEN(C.WorkReportSeq) -1 ) END		AS WorkReportSeq,
			0,
			0,
			C.IsShip,
		    '', 
		    '',
		    '',
			
			''  AS FullShipName,	--������
			'',													--�𼱸�
			1,													--������Ƚ��(�������ϰ��� ������ 1�̴�, �𼱺��� 1�Ǿ� �����ֱ� ������)
			''							AS InDateTime,			--������
			''							AS OutDateTime,			--������
			0							AS DiffApproachTime,	--�۾��ð�
			C.WorkDatecnt				AS WorkDatecnt,			--�۾��ϼ�
			C.WorkQty					AS WorkQty,				--����
			C.TodayMTWeight				AS TodayMTWeight,		--�۾���(MT)
			C.TodayCBMWeight			AS TodayCBMWeight,		--�۾���(CBM)
			C.WorkCnt					AS WorkCnt,				--�۾��׸��
			C.PJTName					AS PJTName,
			C.PJTNo						AS PJTNo,
			C.PJTTypeName				AS PJTTypeName,
			C.WorkDateYM
		  FROM  (
							SELECT A.ContractSeq, 
								   A.ShipSeq, 
								   A.ShipSerl,
								   A.IsShip,
								   B.WorkDatecnt,
								   C.WorkQty,
								   C.TodayMTWeight,
								   C.TodayCBMWeight,
								   D.WorkCnt,
								   E.WorkReportSeq,
								   F.PJTSeq,
								   F.PJTName,
								   F.PJTNo,
								   G.PJTTypeName,
								   A.WorkDateYM
							  FROM #tmpShipDetail AS A
								   --���������� �۾��ϼ� ���ϱ�
								   --�������� �������� �۾��� �־ �ش� �۾����� 1�� �ľ��ϱ� ������ Union���� �ߺ��� �����ϰ�
								   --Count�Ѵ�.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM, COUNT(1) AS WorkDateCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.WorkDate
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.WorkDate
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM
											) AS B 
										   ON B.ContractSeq		= A.ContractSeq
										  AND B.ShipSeq			= A.ShipSeq
										  AND B.ShipSerl		= A.ShipSerl
										  AND B.PJTSeq			= A.PJTSeq
										  AND B.WorkDateYM		= A.WorkDateYM
								  LEFT  JOIN (
												--����Է��� û���׸� -�۾��׸� ���ο� ���ε� �۾��� ������������.
												SELECT B.ContractSeq,
													   A.ShipSeq,
													   A.ShipSerl,
													   A.PJTSeq,
													   LEFT(A.WorkDate, 6)		AS WorkDateYM,
													   SUM(A.TodayQty)			AS WorkQty,
													   SUM(A.TodayMTWeight)		AS TodayMTWeight,
													   SUM(A.TodayCBMWeight)	AS TodayCBMWeight
												  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
													   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
															   ON B.CompanySeq	= A.CompanySeq
															  AND B.PJTSeq		= A.PJTSeq
													   INNER JOIN #tmpWorktype AS C
															   ON C.PJTSeq		= A.PJTSeq
															  AND C.UMWorkType	= A.UMWorkType
												 WHERE A.CompanySeq	= @CompanySeq
												   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																SELECT 1
																  FROM #tmpShipDetail 
																  WHERE WorkReportSeq	= A.WorkReportSeq
																   AND IsShip			= '0'
															)
												 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6)
											) AS C 
										   ON C.ContractSeq	= A.ContractSeq
										  AND C.ShipSeq		= A.ShipSeq
										  AND C.ShipSerl	= A.ShipSerl
										  AND C.PJTSeq		= A.PJTSeq
										 AND C.WorkDateYM	= A.WorkDateYM
								   --���������� �۾��׸�� ���ϱ�
								   --�ٸ����� �������� �۾��� �־ �ش� �۾��׸��� 1�� ���������ϱ� ������ Union���� �ߺ��� �����ϰ�
								   --Count�Ѵ�.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM, COUNT(1) AS WorkCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.UMWorkType
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--�ش� ������ �Ȱɸ� �ٸ����� �ִ� �����͵� �����´�.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.UMWorkType
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM
											) AS D 
										   ON D.ContractSeq	= A.ContractSeq
										  AND D.ShipSeq		= A.ShipSeq
										  AND D.ShipSerl	= A.ShipSerl
										  AND D.PJTSeq		= A.PJTSeq
										  AND D.WorkDateYM	= A.WorkDateYM
								   --�ϳ��� ��û���ǿ� � �۾����������ڵ尡 �ɷ��ִ��� ','�� �����Ͽ� �����ֱ�.
								   LEFT  JOIN (
												SELECT ContractSeq, ShipSeq, ShipSerl, PJTSeq, WorkDateYM,
														(
															SELECT CONVERT(NVARCHAR(100), WorkReportSeq) + ','
															  FROM #tmpShipDetail
															 WHERE ShipSeq		= A.ShipSeq
															   AND ShipSerl		= A.ShipSerl
															   AND ContractSeq	= A.ContractSeq
															   AND WorkDateYM	= A.WorkDateYM
															   AND PJTSeq		= A.PJTSeq
															 ORDER BY WorkReportSeq for xml path('')
															) AS WorkReportSeq
												  FROM #tmpShipDetail AS A
												 WHERE A.IsSHip	= '0'
												 GROUP BY ContractSeq, ShipSeq, ShipSerl, WorkDateYM, PJTSeq
											) AS E
										   ON E.ContractSeq	= A.ContractSeq
										  AND E.ShipSeq		= A.ShipSeq
										  AND E.ShipSerl	= A.ShipSerl
										  AND E.WorkDateYM	= A.WorkDateYM
										  AND E.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTProject AS F WITH(NOLOCK)
										   ON F.CompanySeq	= @CompanySeq
										  AND F.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTType AS G WITH(NOLOCK)
										   ON G.companySeq	= F.CompanySeq
										  AND G.PJTTypeSeq	= F.PJTTypeSeq
							 WHERE IsShip	= '0'	--��û���ϰ��
							 GROUP BY A.ContractSeq,	A.ShipSeq,				A.ShipSerl,			B.WorkDatecnt, 
									  C.WorkQty,		C.TodayMTWeight,		C.TodayCBMWeight,	D.WorkCnt,	 
									  E.WorkReportSeq,	F.PJTSeq,				F.PJTName,			G.PJTTypeName,	
									  A.IsShip,			F.PJTNo,				A.WorkDateYM
						) AS C 
			   LEFT  JOIN MNPT_TPJTShipDetail AS A WITH(NOLOCK)
					   ON A.ShipSeq		= C.ShipSeq
					  AND A.ShipSerl	= C.ShipSerl
			   LEFT  JOIN MNPT_TPJTShipMaster AS B WITH(NOLOCK)
					   ON B.CompanySeq	= A.CompanySeq
					  AND B.ShipSeq		= A.ShipSeq
	     WHERE EXISTS (
						SELECT 1
						  FROM #tmpShipDetail
						 WHERE ShipSeq	= C.ShipSeq
						   AND ShipSerl	= C.ShipSerl
						   AND IsShip	= '0'
					)
		   AND C.WorkDateYM	BETWEEN @ChargeFrDate AND @ChargeToDate
	END
	--���� û�������� �������� �ִ°� �����ϸ� ������ ���� ������ �����ϱ�,
	--���������ִ� �����ͷ� û�������ҰŴϱ�..
	DELETE #tmpShipResult
	  FROM #tmpShipResult AS A
	 WHERE ShipSeq	= 0
	   AND EXISTS (
					SELECT 1
					  FROM #tmpShipResult
					 WHERE ContractSeq	= A.ContractSeq
					   AND PJTseq		= A.PJTSeq
					   AND ChargeDate	= A.ChargeDate
					   ANd ShipSeq		<> 0
				)

	--������ �������� �ʴ� ����� ����� ������Ʈ, ������Ʈ��ȣ, ȭ�¸� �����ְ�
	--������ �����ϴ� ����� �������Ҷ� ���� ������Ʈ, ������Ʈ��ȣ, ȭ�¸� �����ش�.
	--�������� ����ɽ� �������� ������Ʈ�� �ϳ��� ��û�� �Ǵ� ��û���� �����ֱ⶧����.
	SELECT ISNULL(A.BizUnitName, '')			AS BizUnitName,
		   A.ContractSeq						AS ContractSeq,
		   A.ContractName						AS ContractName,
		   A.ContractNo							AS ContractNo,
		   A.PJTName							AS PJTName,
		   A.PJTNo								AS PJTNo,
		   ISNULL(A.CustName, '')				AS CustName,
		   ISNULL(A.PJTTypeName, '')			AS PJTTypeName,
		   ISNULL(A.UMContractTypeName, '')		AS UMContractTypeName,
		   ISNULL(A.UMContractKindName, '')		AS UMContractKindName,
		   ISNULL(A.UMChargeTypeName, '')		AS UMChargeTypeName,
		   ISNULL(A.ContractFrDate, '')			AS ContractFrDate,
		   ISNULL(A.ContractToDate, '')			AS ContractToDate,
		   ISNULL(A.IsFakeContract, '0')		AS IsFakeContract,
		   ISNULL(A.IsContractSideFee, '0')		AS IsContractSideFee,
		   ISNULL(A.IsContractLoadFee ,'0')		AS IsContractLoadFee,
		   ISNULL(A.IsContractStorageFee, '')	AS IsContractStorageFee,
		   A.PJTSeq								AS PJTSeq,
		   ''									AS WorkReportSeq,
		   0									AS ShipSeq,
		   0									AS ShipSerl,
		   A.IsShip								AS IsShip,
		   ''									AS IFShipCode,
		   ''									AS ShipYear,
		   ''									AS ShipSerl2,
		   ''									AS FullShipName,
		   ''									AS EnShipName,
		   0									AS ShipCnt,
		   ''									AS InDateTime,
		   ''									AS OutDateTime,
		   0									AS ApproachDateTime,
		   ''									AS WorkDate,
		   0									AS WorkQty,
		   0									AS TodayMTWeight,
		   0									AS TodayCBMWeight,
		   0									AS WorkCnt,
		   ChargeDate							AS ChargeDate,
		   '0'									AS IsCNT,
		   '0'									AS IsDock
	  INTO #tmpResult2
	  FROM #tmpContract AS A
	 WHERE NOT EXISTS (
						SELECT 1
						  FROM #tmpShipResult
						 WHERE ContractSeq	= A.ContractSeq
						   AND ChargeDate	= A.ChargeDate
						   AND PJTSeq		= A.PJTSeq
					)
	UNION ALL
	SELECT DISTINCT 
	       ISNULL(B.BizUnitName, '')			AS BizUnitName,
		   B.ContractSeq						AS ContractSeq,
		   B.ContractName						AS ContractName,
		   B.ContractNo							AS ContractNo,
		   A.PJTName							AS PJTName,
		   A.PJTNo								AS PJTNo,
		   ISNULL(B.CustName, '')				AS CustName,
		   ISNULL(A.PJTTypeName, '')			AS PJTTypeName,
		   ISNULL(B.UMContractTypeName, '')		AS UMContractTypeName,
		   ISNULL(B.UMContractKindName, '')		AS UMContractKindName,
		   ISNULL(B.UMChargeTypeName, '')		AS UMChargeTypeName,
		   ISNULL(B.ContractFrDate, '')			AS ContractFrDate,
		   ISNULL(B.ContractToDate, '')			AS ContractToDate,
		   ISNULL(B.IsFakeContract, '')			AS IsFakeContract,
		   ISNULL(B.IsContractSideFee, '0')		AS IsContractSideFee,
		   ISNULL(B.IsContractLoadFee, '0')		AS IsContractLoadFee,
		   ISNULL(B.IsContractStorageFee, '0')	AS IsContractStorageFee,
		   ISNULL(A.PJTSeq, '')					AS PJTSeq,
		   ISNULL(A.WorkReportSeq, '')			AS WorkReportSeq,
		   ISNULL(A.ShipSeq, 0)					AS ShipSeq,
		   ISNULL(A.ShipSerl, 0)				AS ShipSerl,
		   ISNULL(A.IsShip, '')					AS IsShip,
		   ISNULL(A.IFShipCode, '')				AS IFShipCode,
		   ISNULL(A.ShipYear, '')				AS ShipYear,
		   ISNULL(A.ShipSerl2, 0)				AS ShipSerl2,
		   ISNULL(A.FullShipName, '')			AS FullShipName,
		   ISNULL(A.EnShipName, '')				AS EnShipName,
		   ISNULL(A.ShipCnt, 0)					AS ShipCnt,
		   ISNULL(A.InDateTime, '')				AS InDateTime,
		   ISNULL(A.OutDateTime, '')			AS OutDateTime,
		   ISNULL(A.ApproachDateTime, 0)		AS ApproachDateTime,
		   ISNULL(A.WorkDate, 0)				AS WorkDate,
		   ISNULL(A.WorkQty, 0)					AS WorkQty,
		   ISNULL(A.TodayMTWeight, 0)			AS TodayMTWeight,
		   ISNULL(A.TodayCBMWeight, 0)			AS TodayCBMWeight,
		   ISNULL(A.WorkCnt, 0)					AS WorkCnt,
		   A.ChargeDate							AS ChargeDate,
		   '0'									AS IsCNT,
		   '0'									AS IsDock
	  FROM #tmpShipResult AS A
		   INNER JOIN #tmpContract AS B
				   ON B.ContractSeq	= A.ContractSeq
	ORDER BY ContractNo, ContractName, PJTNo, PJTName, ChargeDate
	--�����̳� ���� �߰� 2017.11.08
	CREATE TABLE #tmpCNTItem (
		ItemSeq	INT
	)
	INSERT INTO #tmpCNTItem
	SELECT DISTINCT ValueSeq
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MajorSeq		= 1016233
	   AND Serl			= 1000003
	--�ش� ������Ʈ�� �����̳� ����ǰ�� (����������ڵ� ���������-û���׸����_mnpt) �� ���εǾ��ִ� û���׸��� �����Ѵٸ� �����̳� ���ο� üũ
	UPDATE #tmpResult2
	   SET IsCNT	= '1'
	  FROM #tmpResult2 AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM _TPJTProject AS Z WITH(NOLOCK)
						   INNER JOIN _TPJTProjectDelivery AS Y WITH(NOLOCK)
								   ON Y.CompanySeq	= Z.CompanySeq
								  AND Y.PJTSeq		= Z.PJTSeq
						   INNER JOIN #tmpCNTItem AS X WITH(NOLOCK)
								   ON X.ItemSeq		= Y.ItemSeq
					 WHERE Z.CompanySeq	= @CompanySeq
					   AND Z.PJTSeq		= A.PJTSeq
				)

	--������ �����ϴ� ��������, ������ �������� �ʴ� �����̳������� ���� �����Ѵٸ�
	--�����Ϸ� �����͸� �о û�������͸� �������ش�..
	INSERT INTO #tmpResult2 (
		BizUnitName,			ContractSeq,				ContractName,			ContractNo,					PJTName,
		PJTNo,					CustName,					PJTTypeName,			UMcontractTypeName,			UMContractKindName,
		UMChargeTypeName,		ContractFrDate,				ContractToDate,			IsFakeContract,				IsContractSideFee,
		IsContractLoadFee,		IsContractStorageFee,		PJTSeq,					WorkReportSeq,				ShipSeq,
		ShipSerl,				IsShip,						IFShipcode,				ShipYear,					ShipSerl2,
		FullShipName,			
		EnShipName,				ShipCnt,					InDateTime,				OutDateTime,
		ApproachDateTime,		WorkDate,					WorkQty,				TodayMTWeight,				TodayCBMWeight,
		WorkCnt,				ChargeDate,					IsCNT,					IsDock
	)

	SELECT
		A.BizUnitName,			A.ContractSeq,				A.ContractName,			A.ContractNo,				A.PJTName,
		A.PJTNo,				A.CustName,					A.PJTTypeName,			A.UMcontractTypeName,		A.UMContractKindName,
		A.UMChargeTypeName,		A.ContractFrDate,			A.ContractToDate,		A.IsFakeContract,			A.IsContractSideFee,
		A.IsContractLoadFee,	A.IsContractStorageFee,		A.PJTSeq,				-1,							C.ShipSeq,
		C.ShipSerl,				A.IsShip,					D.IFShipCode,			LEFT(D.ShipSerlNo, 4),		RIGHT(D.ShipSerlNo, 3),
		D.IFShipCode + '-' + LEFT(D.ShipSerlNo, 4) + '-' + RIGHT(D.ShipSerlNo, 3),
		E.EnShipName,			1,							LEFT(D.InDateTime, 8),	LEFT(D.OutDateTime, 8),
		D.DiffApproachTime,		0,							C.Qty,					0,							0,
		0,						LEFT(D.OutDateTime, 6),		'1',					'0'
	  FROM #tmpResult2 AS A
		   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS B
				   ON B.CompanySeq	= @CompanySeq
				  AND B.PJTSeq		= A.PJTSeq
		   INNER JOIN (
						SELECT Z.ShipSeq, Z.ShipSerl, SUM(Z.Qty) AS Qty
						  FROM mnpt_TPJTEECNTRReport AS Z
							   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS Y
									   ON Y.CompanySeq	= Z.CompanySeq
									  AND Y.ShipSeq		= Z.ShipSeq
									  AND Y.ShipSerl	= Z.ShipSerl
							   INNER JOIN (
												SELECT ShipSeq, ShipSerl, LEFT(OutDAteTime, 6) AS OutDate
												  FROM mnpt_TPJTShipDetail
												 GROUP BY ShipSeq, ShipSerl, LEFT(OutDAteTime, 6)
											) AS T 
									   ON T.ShipSeq		= Y.ShipSeq
									  AND T.ShipSerl	= Y.ShipSerl
							   INNER JOIN #tmpResult2 AS X
									   ON X.PJTSeq		= Y.PJTSeq
									  AND X.ChargeDate	= T.OutDate
							   INNER JOIN _TPJTProjectDelivery AS U 
									   ON U.CompanySeq	= @CompanySeq
									  AND U.ItemSeq		= Z.ItemSeq
						 WHERE Z.CompanySeq	= @CompanySeq
						 GROUP BY Z.ShipSeq,  Z.ShipSerl
					) AS C
				   ON C.ShipSeq		= B.ShipSeq
				  AND C.ShipSerl	= B.ShipSerl
		   INNER JOIN mnpt_TPJTShipDetail AS D
				   ON D.CompanySeq	= @CompanySeq
				  AND D.ShipSeq		= C.ShipSeq
				  AND D.ShipSerl	= C.ShipSerl
				  AND LEFT(D.OutDateTime, 6)	= A.ChargeDate
		   INNER JOIN mnpt_TPJTShipMaster AS E
				   ON E.CompanySeq	= D.CompanySeq
				  AND E.ShipSeq		= D.ShipSeq
	  WHERE A.IsCNT			= '1'
	    AND A.ShipSeq		<> 0
		AND A.WorkReportSeq = ''
	    AND (A.ShipSeq	<> C.ShipSeq or A.ShipSerl <> c.ShipSerl)
		AND LEFT(D.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate
	--�۾������� ���� �����̳�û���׸��� �����ϴ� ������Ʈ��.
	--�����̳ʽ����� �ִ� ���������� �� ������ �����ش�.
	UPDATE #tmpResult2
	   SET ShipSeq			= C.ShipSeq,
	       ShipSerl			= C.ShipSerl,
		   IFShipCode		= D.IFShipCode,
		   ShipYear			= LEFT(D.ShipSerlNo, 4),
		   ShipSerl2		= RIGHT(D.ShipSerlNo, 3),
		   FullShipName		= D.IFShipCode + '-' + LEFT(D.ShipSerlNo, 4) + '-' + RIGHT(D.ShipSerlNo, 3),
		   EnShipName		= E.EnShipName,
		   ShipCnt			= 1,
		   InDateTime		= LEFT(D.InDateTime, 8),
		   OutDateTime		= LEFT(D.OutDateTime, 8),
		   ApproachDateTime	= D.DiffApproachTime,
		   WorkQty			= C.Qty,
		   WorkReportSeq	= -1
	  FROM #tmpResult2 AS A
		   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS B
				   ON B.CompanySeq	= @CompanySeq
				  AND B.PJTSeq		= A.PJTSeq
		   INNER JOIN (
						SELECT Z.ShipSeq, Z.ShipSerl, SUM(Z.Qty) AS Qty
						  FROM mnpt_TPJTEECNTRReport AS Z
							   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS Y
									   ON Y.CompanySeq	= Z.CompanySeq
									  AND Y.ShipSeq		= Z.ShipSeq
									  AND Y.ShipSerl	= Z.ShipSerl
							   INNER JOIN (
												SELECT ShipSeq, ShipSerl, LEFT(OutDAteTime, 6) AS OutDate
												  FROM mnpt_TPJTShipDetail
												 GROUP BY ShipSeq, ShipSerl, LEFT(OutDAteTime, 6)
											) AS T 
									   ON T.ShipSeq		= Y.ShipSeq
									  AND T.ShipSerl	= Y.ShipSerl
							   INNER JOIN #tmpResult2 AS X
									   ON X.PJTSeq		= Y.PJTSeq
									  AND X.ChargeDate	= T.OutDate
							   INNER JOIN _TPJTProjectDelivery AS U 
									   ON U.CompanySeq	= @CompanySeq
									  AND U.ItemSeq		= Z.ItemSeq
						 WHERE Z.CompanySeq	= @CompanySeq
						 GROUP BY Z.ShipSeq,  Z.ShipSerl
					) AS C
				   ON C.ShipSeq		= B.ShipSeq
				  AND C.ShipSerl	= B.ShipSerl
		   INNER JOIN mnpt_TPJTShipDetail AS D
				   ON D.CompanySeq				= @CompanySeq
				  AND D.ShipSeq					= C.ShipSeq
				  AND D.ShipSerl				= C.ShipSerl
				  AND LEFT(D.OutDateTime, 6)	= A.ChargeDate
		   INNER JOIN mnpt_TPJTShipMaster AS E
				   ON E.CompanySeq	= D.CompanySeq
				  AND E.ShipSeq		= D.ShipSeq
	  WHERE A.IsCNT		= '1'
	    AND A.ShipSeq	= 0
		AND LEFT(D.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate
	--���ȷ� ������Ʈ�� ������ �����ֱ�.
	INSERT INTO #tmpResult2 (
		BizUnitName,			ContractSeq,				ContractName,			ContractNo,					PJTName,
		PJTNo,					CustName,					PJTTypeName,			UMcontractTypeName,			UMContractKindName,
		UMChargeTypeName,		ContractFrDate,				ContractToDate,			IsFakeContract,				IsContractSideFee,
		IsContractLoadFee,		IsContractStorageFee,		PJTSeq,					WorkReportSeq,				ShipSeq,
		ShipSerl,				IsShip,						IFShipcode,				ShipYear,					ShipSerl2,
		FullShipName,			
		EnShipName,				ShipCnt,					InDateTime,				OutDateTime,
		ApproachDateTime,		WorkDate,					WorkQty,				TodayMTWeight,				TodayCBMWeight,
		WorkCnt,				ChargeDate,					IsCNT,					IsDock
	)
	SELECT 
		DISTINCT 
		G.BizUnitName,			A.ContractSeq,				A.ContractName,			A.ContractNo,				I.PJTNAme,
		I.PJTNo,				H.CustName,					J.PJTTypeName,			K.MinorName,				L.MinorName,
		M.MinorName,			A.ContractFrDate,			A.ContractToDate,		A.IsFakeContract,			'1',
		'0',					'0',						C.PJTSeq,				'',							D.shipSeq,
		D.ShipSerl,				'0',						E.IFShipCode,			LEFT(E.ShipSerlNo, 4),		RIGHT(E.ShipSerlNo, 3),
		E.IFShipCode + '-' + LEFT(E.ShipSerlNo, 4) + '-' + RIGHT(E.ShipSerlNo, 3),	
		F.EnShipName,			1,							LEFT(E.InDateTime, 8),	LEFT(E.OutDateTime, 8),
		E.DiffApproachTime,		0,							0,						0,							0,							
		0,						LEFT(E.OutDateTime, 6),		'0',					'1'	
	  FROM mnpt_TPJTContract AS A WITH(NOLOCK)
		   LEFT  JOIN _TDAUMinorValue AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.MinorSeq	= A.UMContractKind
				  AND B.Serl		= 1000002
				  AND B.MajorSeq	= 1015778
		   LEFT  JOIN mnpt_TPJTProject AS C WITH(NOLOCK)
				   ON C.CompanySeq	= A.CompanySeq
				  AND C.ContractSeq	= A.ContractSeq
		   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS D WITH(NOLOCK)
				   ON D.CompanySeq	= C.CompanySeq
				  AND D.DockPJTSeq	= C.PJTSeq
		   INNER JOIN mnpt_TPJTShipDetail AS E WITH(NOLOCK)
				   ON E.CompanySeq	= D.CompanySeq
				  AND E.ShipSeq		= D.ShipSeq
				  AND E.ShipSerl	= D.ShipSerl
		   INNER JOIN mnpt_TPJTShipMaster AS F WITH(NOLOCK)
				   ON F.CompanySeq	= E.CompanySeq
				  AND F.ShipSeq		= E.ShipSeq
		   LEFT  JOIN _TDABizUnit AS G WITH(NOLOCK)
				   ON G.CompanySeq	= A.CompanySeq
				  AND G.BizUnit		= A.BizUnit
		   LEFT  JOIN _TDACust AS H WITH(NOLOCK)
				   ON H.CompanySeq	= A.CompanySeq
				  AND H.CustSeq		= A.CustSeq
		   LEFT  JOIN _TPJTProject AS I WITH(NOLOCK)
				   ON I.CompanySeq	= C.CompanySeq
				  AND I.PJTSeq		= C.PJTSeq
		   LEFT  JOIN _TPJTType AS J WITH(NOLOCK)
				   ON J.CompanySeq	= I.CompanySeq
				  AND J.PJTTypeSeq	= I.PJTTypeSeq
		   LEFT  JOIN _TDAUMinor AS K WITH(NOLOCK)
				   ON K.CompanySeq	= A.CompanySeq
				  AND K.MinorSeq	= A.UMContractType
		   LEFT  JOIN _TDAUMinor AS L WITH(NOLOCK)
				   ON L.CompanySeq	= A.CompanySeq
				  AND L.MinorSeq	= A.UMContractKind
		   LEFT  JOIN _TDAUMinor AS M WITH(NOLOCK)
				   ON M.CompanySeq	= A.CompanySEq
				  AND M.MinorSeq	= A.UMChargeType
	 WHERE A.CompanySeq	= @CompanySeq
	   AND B.ValueText	= '1'
	   AND LEFT(E.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate


	--�۾����غ��� üũ�� �۾��� ���� ������
	IF @UMExampleKind = 1015856003
	BEGIN
	  DELETE #tmpResult2
		FROM #tmpResult2
	   WHERE WorkReportSeq = ''
	 END

	SELECT A.*,
		   ISNULL(B.InvoiceSeq, 0)  AS InvoiceSeq
	  INTO #tmpResult3
	  FROM #tmpResult2 AS A 
		   LEFT  JOIN (
						SELECT InvoiceSeq, 
							   ContractSeq, 
							   OldShipSeq		AS ShipSeq,		--OldShipSeq�� ����. û���Է¿��� ������ �ű��Է� �� ���������ϱ⶧�� 2017.11.08 
							   OldShipSerl		AS ShipSerl,	--OldShipSerl�� ����. û���Է¿��� ������ �ű��Է� �� ���������ϱ⶧�� 2017.11.08 
							   PJTSeq,
							   CASE WHEN OldShipSeq = 0 THEN ChargeDate ELSE '' END AS ChargeDate
						  FROM mnpt_TPJTLinkInvoiceItem
						 WHERE CompanySeq	= @CompanySeq
						 GROUP BY InvoiceSeq, ContractSeq, OldShipSeq, OldShipSerl, PJTSeq,
								  CASE WHEN OldShipSeq = 0 THEN ChargeDate ELSE '' END 
					) AS B 
				   ON B.ContractSeq	= A.ContractSeq
				  AND B.ShipSeq		= A.ShipSeq
				  AND B.ShipSerl	= A.ShipSerl
				  AND B.PJTSeq		= A.PJTSeq
				  ANd B.ChargeDate	= CASE WHEN A.ShipSeq = 0 THEN A.ChargeDate ELSE B.ChargeDate END
     WHERE (@IFShipCode			= '' OR A.IFShipCode	LIKE @IFShipCode	+ '%')
	   AND (@ShipYear			= '' OR A.ShipYear		LIKE @ShipYear		+ '%')
	   AND (@ShipSerl			= '' OR A.ShipSerl2		LIKE @ShipSerl		+ '%')
	   AND (@ShipSeq			= 0  OR A.ShipSeq		= @ShipSeq)
	   AND (@CustName			= '' OR A.CustName		LIKE @CustName		+ '%')
	   AND (@PJTName			= '' OR A.PJTName		LIKE @PJTName		+ '%')
	   AND (@PJTTypeName		= '' OR A.PJTTypeName	LIKE @PJTTypeName	+ '%')
	   AND (@PJTNo				= '' OR A.PJTNo			LIKE @PJTNo			+ '%')
	   AND (@ContractName		= '' OR A.ContractName	LIKE @ContractName	+ '%')
	   AND (@ContractNo			= '' OR A.ContractNo	LIKE @ContractNo	+ '%')

	--û�� or ������ ���ȷ�, �Ͽ���, ������ ���� Insert
	CREATE TABLE #tmpItemLClass2(
		InvoiceSeq				INT,
		InvoiceNo				NVARCHAR(100),	--û����ȣ
		IsContractSideFee		NCHAR(1),	--���ȷ�(û��)
		IsContractLoadFee		NCHAR(1),	--�Ͽ���(û��)
		IsContractStorageFee	NCHAR(1),	--������(û��)
		IsDirectSideFee			NCHAR(1),	--���ȷ�(����)
		IsDirectLoadFee			NCHAR(1),	--�Ͽ���(����)
		IsDirectStorageFee		NCHAR(1),	--������(����)
		IsChargeComplete		NCHAR(1),	--û���Ϸ�
		IsDirect				NCHAR(1)	--�����Է�
		
	)
	/*
	û���������ε� ǰ���з���, û���Է�ȭ�鿡�� �Է��� ǰ���з��� �񱳴� ��ũ���̺�(mnpt_TPJTLinkInvoiceItem)�� PgmSeq�� �����Ѵ�
	û���������� ������ û���� PgmSeq = 13820012�̰� , û���Է¿��� ������Է��� û���� PgmSeq = 13820018�̴�
	*/
	INSERT INTO #tmpItemLClass2 (
		InvoiceSeq,
		InvoiceNo,
		IsContractSideFee,
		IsContractLoadFee,
		IsContractStorageFee,
		IsDirectSideFee,
		IsDirectLoadFee,
		IsDirectStorageFee,
		IsChargeComplete,
		IsDirect
	)
	SELECT
		A.InvoiceSeq,
		A.InvoiceNo,
		CASE WHEN ISNULL(B.IsContractSideFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(C.IsContractLoadFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(D.IsContractStorageFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(E.IsContractSideFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(F.IsContractLoadFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(G.IsContractStorageFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(Z.IsComplete, 0) <> ISNULL(Z.IsCnt, 0)	THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(Y.IsComplete, 0) = 0				THEN '0' ELSE '1' END
	  FROM _TSLInvoice AS A WITH(NOLOCK)
		   LEFT  JOIN mnpt_TSLInvoice AS Y WITH(NOLOCK)
				   ON Y.CompanySeq	= A.CompanySeq
				  AND Y.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT InvoiceSeq, 
							   SUM(CONVERT(INT, IsComplete))	AS IsComplete,
							   COUNT(1)							AS IsCnt
						  FROM mnpt_TSLInvoiceItem
						 WHERE CompanySeq	= @CompanySeq
						 GROUP BY InvoiceSeq
						) AS Z 
				   ON Z.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractSideFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvSideFee
							AND A.PgmSeq			= 13820012
						  GROUP BY A.InvoiceSeq
					) AS B 
				   ON B.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractLoadFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvLoadFee
							AND A.PgmSeq			= 13820012
						  GROUP BY A.InvoiceSeq
					) AS C 
				   ON C.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractStorageFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvStorageFee
							AND A.PgmSeq			= 13820012
						  GROUP BY A.InvoiceSeq
					) AS D 
				   ON D.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractSideFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvSideFee
							AND A.PgmSeq			= 13820018
						  GROUP BY A.InvoiceSeq
					) AS E 
				   ON E.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractLoadFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvLoadFee
							AND A.PgmSeq			= 13820018
						  GROUP BY A.InvoiceSeq
					) AS F 
				   ON F.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractStorageFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvStorageFee
							AND A.PgmSeq			= 13820018
						  GROUP BY A.InvoiceSeq
					) AS G 
				   ON G.InvoiceSeq	= A.InvoiceSeq
		
	 WHERE A.CompanySeq	= @CompanySeq
	   AND EXISTS (
					SELECT 1
					  FROM #tmpResult3
					 WHERE InvoiceSeq	= A.InvoiceSeq
				)

	   SELECT A.*,
			  B.InvoiceNo,
			  CASE WHEN A.InvoiceSeq <> 0				THEN '1' ELSE '0' END IsChargeCreate,
			  CASE WHEN B.IsContractSideFee <> 0		THEN '1' ELSE '0' END IsChargeSideFee,
			  CASE WHEN B.IsContractLoadFee <> 0		THEN '1' ELSE '0' END IsChargeLoadFee,
			  CASE WHEN B.IsContractStorageFee <> 0		THEN '1' ELSE '0' END IsChargeStorageFee,
			  CASE WHEN B.IsDirectSideFee <> 0			THEN '1' ELSE '0' END IsDirectSideFee,
			  CASE WHEN B.IsDirectLoadFee <> 0			THEN '1' ELSE '0' END IsDirectLoadFee,
			  CASE WHEN B.IsDirectStorageFee <> 0		THEN '1' ELSE '0' END IsDirectStorageFee,
			  CASE WHEN B.IsChargeComplete <> 0			THEN '1' ELSE '0' END IsChargeComplete,
			  ISNULL(B.IsChargeComplete, '0')	AS IsChargeComplete,
			  ISNULL(B.IsDirect, '0')			AS IsDirect,
			  CASE WHEN A.IsShip = '0' AND A.IsDock = '0' THEN '0'
				   ELSE ( CASE WHEN ISNULL(C.IsCfm, '0') = '0' THEN '0' ELSE '1' END )
				   END AS IsComplete
	     FROM #tmpResult3 AS A
			  LEFT JOIN (
							SELECT InvoiceSeq, 
								   InvoiceNo,
								   IsContractSideFee, 
								   IsContractLoadFee, 
								   IsContractStorageFee,
								   IsDirectSideFee,
								   IsDirectLoadFee,
								   IsDirectStorageFee,
								   IsChargeComplete,
								   IsDirect
							  FROM #tmpItemLClass2
							 GROUP BY InvoiceSeq, 
									  InvoiceNo,
									  IsContractSideFee, 
									  IsContractLoadFee, 
									  IsContractStorageFee,
									  IsDirectSideFee,
									  IsDirectLoadFee,
									  IsDirectStorageFee,
									  IsChargeComplete,
									  IsDirect
						) AS B
					  ON B.Invoiceseq	= A.InvoiceSeq
			  LEFT  JOIN mnpt_TPJTShipWorkPlanFinish  AS C WITH(NOLOCK)
					  ON C.CompanySeq	= @CompanySeq
					 AND C.ShipSeq		= A.ShipSeq
					 AND C.ShipSerl		= A.ShipSerl
					 AND A.PJTSeq		= CASE WHEN A.IsDock = '1' THEN C.DockPJTSeq ELSE C.PJTSeq END
		WHERE (@UMChargeCreate = 1015860001 OR (@UMChargeCreate = 1015860002 AND A.Invoiceseq = 0)			--û������
											OR (@UMChargeCreate = 1015860003 AND A.InvoiceSeq <> 0)
				)
		  AND  (@UMChargeComplete = 1015861001 OR (@UMChargeComplete = 1015861002 AND ISNULL(B.IsChargeComplete, '0') = '0')	--û���Ϸ�
											OR (@UMChargeComplete = 1015861003 AND ISNULL(B.IsChargeComplete, '0') <> '0')
				)
		ORDER BY A.BizUnitName, A.ContractNo, A.ChargeDate, A.PJTNo
