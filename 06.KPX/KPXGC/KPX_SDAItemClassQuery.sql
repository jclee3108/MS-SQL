
IF OBJECT_ID('KPX_SDAItemClassQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemClassQuery
GO 

-- 2014.11.04 

-- ǰ��з� ��ȸ by����õ
/*************************************************************************************************          
 ��  �� - ǰ��з� ��ȸ      
 �ۼ��� - 2008.6.  : CREATED BY JMKIM      
*************************************************************************************************/          
CREATE PROCEDURE KPX_SDAItemClassQuery    
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
              @ItemSeq        INT    
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument            
      
    SELECT  @ItemSeq     = ISNULL(ItemSeq, '')    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
    WITH ( ItemSeq  INT )            
    
    SELECT @ItemSeq  = ISNULL(LTRIM(RTRIM(@ItemSeq)),   0)    
    
    SELECT   ISNULL(C.MajorName,'') AS UMItemClassName -- ǰ��з�����    
            ,ISNULL(A.UMajorItemClass,0) AS UMajorItemClass -- ǰ��з������ڵ�    
            ,ISNULL(D.MinorName,'') AS ItemClassName -- ǰ��з�����    
            ,ISNULL(B.UMItemClass,0) AS UMItemClass  -- ǰ��з������ڵ�    
            ,ISNULL(A.IsItem,'0') AS IsItem    
     FROM _TDADefineItemClass A With(Nolock) LEFT OUTER JOIN KPX_TDAItemClass B With(Nolock)    
                                               ON A.CompanySeq = B.CompanySeq    
                                              AND A.UMajorItemClass = B.UMajorItemClass    
                                              AND B.ItemSeq = @ItemSeq    
                                             LEFT OUTER JOIN _TDAUMajor C With(Nolock)    
                                               ON A.CompanySeq = C.CompanySeq    
                                              AND A.UMajorItemClass = C.MajorSeq    
                                             LEFT OUTER JOIN _TDAUMinor D With(Nolock)    
                                               ON B.CompanySeq = D.CompanySeq    
                                              AND B.UMItemClass = D.MinorSeq    
    
    WHERE 1 = 1      
      AND (A.CompanySeq = @CompanySeq)    
      AND (A.IsItem = '1')    
    Order by A.Priority    
    
RETURN        
  
  