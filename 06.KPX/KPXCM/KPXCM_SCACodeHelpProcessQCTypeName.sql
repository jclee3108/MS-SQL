IF OBJECT_ID('KPXCM_SCACodeHelpProcessQCTypeName') IS NOT NULL
    DROP PROC KPXCM_SCACodeHelpProcessQCTypeName
GO 

-- v2016.05.30 
         
 -- �˻����_KPX by����õ   
 CREATE PROC KPXCM_SCACodeHelpProcessQCTypeName
     @WorkingTag     NVARCHAR(1),                                
     @LanguageSeq    INT,                                
     @CodeHelpSeq    INT,                                
     @DefQueryOption INT,              
     @CodeHelpType   TINYINT,                                
     @PageCount      INT = 20,                     
     @CompanySeq     INT = 1,                               
     @Keyword        NVARCHAR(200) = '',                                
     @Param1         NVARCHAR(50) = '',     
     @Param2         NVARCHAR(50) = '',     
     @Param3         NVARCHAR(50) = '',                    
     @Param4         NVARCHAR(50) = ''       
         
     WITH RECOMPILE              
 AS        
     SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED            
           
     SET ROWCOUNT @PageCount             
       
     CREATE TABLE #QCList
     (
        QCSeq       INT
     )
       
     IF @Param2 <> '1'  
     BEGIN   
           
       SELECT QCTypeName,   
           QCType  
         FROM KPX_TQCQAProcessQCType WITH(NOLOCK)     
        WHERE CompanySeq = @CompanySeq       
          AND QCTypeName LIKE @Keyword      
                AND (@Param1 = 0 OR CASE WHEN @Param1 = 1000522002 THEN TermQc      -- ��ȿ�Ⱓ�˻�  
                         WHEN @Param1 = 1000522004 THEN ProcQC      -- �����˻�  
                         WHEN @Param1 = 1000522001 THEN StockQC     -- ���˻�  
                         WHEN @Param1 = 1000522005 THEN OutQC       -- ���ϰ˻��Ƿ�(��ũ�θ�)  
                         WHEN @Param1 = 1000522006 THEN PackQC      -- ����˻�   
                         WHEN @Param1 IN (1000522007,1000522008) THEN InQC        -- ���԰˻�  
                         END = 1000498001)  
     END       
     ELSE  --�ڵ����� �� ǰ�����԰ݵ�Ͽ� ��ϵ� �˻���� �� �ڵ� ����  
     BEGIN  
     
     
        INSERT INTO #QCList(QCSeq)
        SELECT DISTINCT A.QCSeq
          FROM KPX_TQCTestResult AS A WITH(NOLOCK) 
                JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                            AND A.QCSeq  = B.QCSeq
        WHERE A.CompanySeq = @CompanySeq
          AND (ISNULL(@Param3,0)=0 OR @Param3='' OR A.ItemSeq = @Param3)  
          AND ( @Param4='' OR A.LotNo = @Param4)  
          AND B.SMTestResult IN ( 6035003, 6035004, 6035005 ) -- �հ�, ���հ�, Ưä 
          AND B.ISSpecial = 0 
          AND B.QCType IN (SELECT DISTINCT QCType FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySEq and IsCOA = '1' ) 
     
     
      SELECT A.QCTypeName,   
             A.QCType  
         FROM KPX_TQCQAProcessQCType AS A WITH(NOLOCK) 
         WHERE A.CompanySeq = @CompanySeq       
             AND A.QCTypeName LIKE @Keyword  
             AND A.QCType IN (SELECT DISTINCT QCType FROM KPX_TQCQAQualityAssuranceSpec WITH(NOLOCK) WHERE CompanySeq=@CompanySeq)  
             AND A.QCType IN (
                              SELECT DISTINCT I.QCType
                               FROM KPX_TQCTestResultItem AS I WITH(NOLOCK) JOIN #QCList AS J ON I.QCSeq = J.QCSeq
                              WHERE I.CompanySeq = @CompanySeq    
                                AND I.QCType <> 0                 
                            UNION 
                            SELECT DISTINCT R.QCType  
                              FROM KPX_TQCTestResult AS R  
                              WHERE R.CompanySeq=@CompanySeq   
                              AND R.QCType <> 0
                              AND (ISNULL(@Param3,0)=0 OR @Param3='' OR R.ItemSeq = @Param3)  
                              AND ( @Param4='' OR R.LotNo = @Param4) 
                                                                  )  
      END  
  
     SET ROWCOUNT 0       
       
   RETURN
GO


