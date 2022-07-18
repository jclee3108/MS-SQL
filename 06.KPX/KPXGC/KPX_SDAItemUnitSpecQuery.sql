 
 IF OBJECT_ID('KPX_SDAItemUnitSpecQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitSpecQuery
GO 

-- v2014.11.04 

-- ǰ������Ӽ� ��ȸ by����õ
 CREATE PROCEDURE KPX_SDAItemUnitSpecQuery  
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
      @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
     DECLARE   @docHandle      INT,  
               @ItemSeq        INT,  
               @UnitSeq        INT,  
               @DicName1       NVARCHAR(100),  
               @DicName2       NVARCHAR(100),   
               @UnitSpecCount  DECIMAL(19,5)  
      SELECT @DicName1 = Word FROM _TCADictionary WITH(NOLOCK) where LanguageSeq = @LanguageSeq AND WordSeq = 3174 -- �Ӽ�����  
     IF @@ROWCOUNT = 0 OR ISNULL( @DicName1, '' ) = '' SELECT @DicName1 = N'�Ӽ�����'  
       
     SELECT @DicName2 = Word FROM _TCADictionary WITH(NOLOCK) where LanguageSeq = @LanguageSeq AND WordSeq = 3083 -- ��  
  IF @@ROWCOUNT = 0 OR ISNULL( @DicName2, '' ) = '' SELECT @DicName2 = N'��'  
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
     
     SELECT  @ItemSeq = ItemSeq  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
     WITH (  ItemSeq     INT)       
      
     CREATE TABLE #TDAInputColumn  
     (  
         Code    INT,  
         Title   NVARCHAR(100)  
     )  
      INSERT INTO #TDAInputColumn  
     SELECT 1, @DicName1  
      INSERT INTO #TDAInputColumn  
     SELECT 2, @DicName2  
      --================================================================================================================================    
     -- �����Ӽ�  
     --================================================================================================================================    
     SELECT IDENTITY(INT, 0, 1)    AS ColIDX,        
            ISNULL( ISNULL( Z.Word, A.MinorName ), '' ) AS TitleName,        
            A.MinorSeq             AS TitleSeq  
       INTO #Temp_TDAItemUnitSpec  
       FROM _TDAUMinor A WITH(NOLOCK)    
       LEFT OUTER JOIN _TCADictionary AS Z WITH(NOLOCK) ON ( Z.LanguageSeq = @LanguageSeq AND A.WordSeq = Z.WordSeq )   
      WHERE A.CompanySeq = @CompanySeq  
        AND A.MajorSeq = 8010  
      ORDER BY A.MinorSeq     
    
     SELECT A.TitleName            AS Title,        
            A.TitleSeq             AS TitleSeq,  
            B.Title                AS Title2,  
            B.Code                 AS TitleSeq2  
       FROM #Temp_TDAItemUnitSpec AS A, #TDAInputColumn AS B   
      ORDER BY A.TitleSeq, B.Code      
      SELECT @UnitSpecCount = COUNT(TitleName)  
       FROM #Temp_TDAItemUnitSpec  
      --================================================================================================================================    
     -- ����  
     --================================================================================================================================    
     SELECT IDENTITY(INT, 0, 1)            AS RowIDX,    
            IsNull(B.UnitName, '')         AS UnitName,    -- ������    
            IsNull(A.UnitSeq, 0)           AS UnitSeq      -- �����ڵ�    
      INTO #Temp_TDAItemUnit  
      FROM KPX_TDAItemUnit          AS A WITH(NOLOCK)     
           LEFT OUTER JOIN _TDAUnit AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                     AND A.UnitSeq    = B.UnitSeq  
     WHERE A.CompanySeq = @CompanySeq    
       AND A.ItemSeq    = @ItemSeq  
     ORDER BY UnitSeq  
      -- �����Ӽ��� ���� ����Ʈ�� ��� ��������� ������ �߻��ϹǷ� ��ȸ������ �ʴ´�.   
     IF @UnitSpecCount = 0  
     BEGIN  
         DELETE FROM #Temp_TDAItemUnit  
     END  
    
     SELECT IsNull(UnitName, '')          AS UnitName,    -- ������    
       IsNull(UnitSeq, 0)            AS UnitSeq      -- �����ڵ�    
      FROM #Temp_TDAItemUnit    
     ORDER BY RowIDX    
      --================================================================================================================================    
     -- �Ӽ���  
       --================================================================================================================================    
     SELECT C.RowIDX   AS RowIDX,    
            B.ColIDX   AS ColIDX,    
            A.SpecUnit AS SpecUnit,  
            A.Value    AS Value  
       FROM KPX_TDAItemUnitSpec         AS A WITH (NOLOCK)  
            JOIN #Temp_TDAItemUnitSpec  AS B ON A.UMSpecCode = B.TitleSeq  
            JOIN #Temp_TDAItemUnit      AS C ON A.UnitSeq    = C.UnitSeq  
      WHERE A.CompanySeq = @CompanySeq  
        AND A.ItemSeq    = @ItemSeq  
     
  RETURN  