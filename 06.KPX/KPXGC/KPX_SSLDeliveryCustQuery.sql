IF OBJECT_ID('KPX_SSLDeliveryCustQuery') IS NOT NULL 
    DROP PROC KPX_SSLDeliveryCustQuery
GO 

-- v2016.01.18 

-- 조회조건 추가 by이재천 
/*************************************************************************************************  

    Ver.20130805

 설  명 - 거래처별 납품처등록 (조회)  
 작성일 - 2008.06  
 작성자 - 박진희  
*************************************************************************************************/  
CREATE PROCEDURE KPX_SSLDeliveryCustQuery
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
            @CustSeq        INT,
            @DVPlaceName    NVARCHAR(100), 
            @Addr           NVARCHAR(100), 
            @Addr2          NVARCHAR(100), 
            @DelvRegSeq     INT 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT 
        @CustSeq        = ISNULL(CustSeq,0),
        @DVPlaceName    = ISNULL(DVPlaceName,''), 
        @Addr           = ISNULL(Addr, ''), 
        @Addr2          = ISNULL(Addr2, ''), 
        @DelvRegSeq     = ISNULL(DelvRegSeq,0)
        
        
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)  
      WITH ( 
            CustSeq        INT, 
            DVPlaceName    NVARCHAR(100),
            Addr           NVARCHAR(100),
            Addr2          NVARCHAR(100),
            DelvRegSeq     INT 
           )
  

  
    SELECT A.DVPlaceSeq                     AS DVPlaceSeq,      --  납품처코드  
           ISNULL(B.CustName,'')            AS CustName,        --  거래처  
           ISNULL(A.DVPlaceName,'')         AS DVPlaceName,     --  납품처  
           ISNULL(B.CustNo,'')				AS CustNo,			-- 거래처번호 
           A.UMCourse                       AS UMCourse,        --  지정운송편  
           ISNULL(C.MinorName,'')           AS UMCourseName,    --  지정운송편 
           ISNULL(A.Addr1,'')               AS Addr,            --  주소1  
           ISNULL(A.Addr2,'')               AS Addr2,           --  주소2  
           A.ZipCode						AS ZipNo,			--	우편번호 하이픈(-) 없이 조회 : 20150706 장경선
           --LEFT(LTRIM(RTRIM(A.ZipCode)),3) + '-' + 
           --RIGHT(LTRIM(RTRIM(A.ZipCode)),3) AS ZipNo,           --  우편번호  
           ISNULL(A.TelNo,'')               AS TelNo,           --  전화번호  
           ISNULL(A.FAX,'')                 AS FAX,             --  팩스번호  
           A.ClientInfoSeq                  AS ClientInfoSeq,   --  담당자코드
           ISNULL(E.FamilyName, '') + 
           ISNULL(E.ClientName, '')         AS ClientInfoName,  --  담당자  
           ISNULL(A.MobileNo,'')            AS MobileNo,        --  휴대전화번호  
           ISNULL(A.Remark,'')              AS Remark,          --  비고  
           A.DelvRegSeq                     AS DelvRegSeq,      --  배송지역코드  
           ISNULL(D.MinorName,'')           AS DelvRegName,     --  배송지역  
           A.CustSeq                        AS CustSeq,         --  거래처코드  
           A.ClientName                     AS ClientName,       -- 납품처담당자
           A.IsUse,
           ISNULL(B.CustNo, '')             AS CustNo           -- 거래처번호 :: 20130930 박성호
      FROM _TSLDeliveryCust AS A WITH(NOLOCK)  
           LEFT OUTER JOIN _TDACust             AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq  
                                                                 AND B.CustSeq    = A.CustSeq  
           LEFT OUTER JOIN _TDAUMinor           AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq  
                                                                 AND C.MinorSeq = A.UMCourse  
--                                                                 AND C.MajorSeq = 8005  
           LEFT OUTER JOIN _TDAUMinor           AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq  
                                                                 AND D.MinorSeq = A.DelvRegSeq  
--                                                                 AND D.MajorSeq = 8006  
           LEFT OUTER JOIN _TSIASClientInfo     AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq  
                                                                 AND E.ClientInfoSeq = A.ClientInfoSeq

     WHERE A.CompanySeq = @CompanySeq  
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)  
       AND (@DVPlaceName = '' OR A.DVPlaceName LIKE (@DVPlaceName + '%'))  
       AND (@Addr = '' OR A.Addr1 LIKE @Addr + '%') 
       AND (@Addr2 = '' OR A.Addr2 LIKE @Addr2 + '%') 
       AND (@DelvRegSeq = 0 OR A.DelvRegSeq = @DelvRegSeq) 
    
     ORDER BY A.DVPlaceSeq  



RETURN  
