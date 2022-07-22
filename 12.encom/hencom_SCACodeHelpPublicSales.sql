IF OBJECT_ID('hencom_SCACodeHelpPublicSales') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpPublicSales
GO 

-- v2017.04.26

/***********************************************************************************************      
 ROCEDURE    - ���޹���_HNCOM    
 DESCRIPTION -       
 ��  ��  ��   - 2106.03.08 by�ڼ���    
 *************************************************************************************************/      
 CREATE PROCEDURE hencom_SCACodeHelpPublicSales      
     @WorkingTag     NVARCHAR(1),      
     @LanguageSeq    INT,      
     @CodeHelpSeq    INT,      
     @DefQueryOption INT, -- 2: direct search      
     @CodeHelpType   TINYINT,      
     @PageCount      INT = 20,      
     @CompanySeq     INT = 0,      
     @Keyword        NVARCHAR(50) = '',      
     @Param1         NVARCHAR(50) = '',  -- �ڱ���ȭ ���Կ���(1=����, 0=����)      
     @Param2         NVARCHAR(50) = '',      
     @Param3         NVARCHAR(50) = '',      
     @Param4         NVARCHAR(50) = '',    
     @ConditionSeq   NVARCHAR(200) = ''    
      -- ���� �߰��� : _TCACodeHelpData�� UseLoginInfo ���� 1�϶��� �Ʒ� �Ķ���� ȣ���.            
 --     , @AccUnit          INT = NULL            
 --     , @BizUnit          INT = NULL            
 --     , @FactUnit         INT = NULL            
 --     , @DeptSeq          INT = NULL            
 --     , @WkDeptSeq        INT = NULL            
 --     , @EmpSeq           INT = NULL            
 --     , @UserSeq          INT = NULL       
          
 AS      
       
 --  select @ConditionSeq    
     DECLARE @SELECTSQL        NVARCHAR(4000),               
             @FROMSQL          NVARCHAR(4000),               
             @WHERESQL         NVARCHAR(4000),                        
             @SQL              NVARCHAR(4000)    
                 
     SET ROWCOUNT @PageCount      
    
    DECLARE @ItemName NVARCHAR(100) 

    SELECT @ItemName = A.ItemName
      FROM _TDAItem AS A WITH(NOLOCK) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = CONVERT(INT,@Param3)
    

     SELECT  A.PPSRegSeq         AS PPSRegSeq,  
             A.PublicSalesNo     AS PublicSalesNo,  
             F.CustName      AS PPCustName ,  
             P.PJTName       AS PPPJTName ,  
             B.ItemName      AS PPItemName ,  
             A.Qty           AS PPQty ,  
             A.CurAmt        AS PPCurAmt ,  
             A.CurVat        AS PPCurVat ,  
             A.Price         AS PPPrice ,  
             A.AssignDate    AS PPAssignDate ,  
             D.DeptName      AS PPDeptName ,  
             A.Remark        AS PPRemark ,  
             A.CustSeq       AS PPCustSeq ,  
             A.PJTSeq        AS PPPJTSeq ,  
             A.ItemSeq       AS PPItemSeq ,  
             A.DeptSeq       AS PPDeptSeq ,
             A.Qty  - ISNULL(O.OutQty,0) AS RestQty   --�ܷ�
     INTO #TMPTable  
     FROM hencom_TSLPrePublicSales AS A WITH(NOLOCK)   
     LEFT OUTER JOIN _TDAItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq       
                                               AND A.ItemSeq = B.ItemSeq    
     LEFT OUTER JOIN  _TDACust         AS F WITH(NOLOCK) ON F.CompanySeq = A.CompanySeq      
                                              AND F.CustSeq = A.CustSeq    
     LEFT OUTER JOIN _TPJTProject AS P WITH(NOLOCK) ON P.CompanySeq = @CompanySeq     
                                                 AND P.PJTSeq = A.PJTSeq    
     LEFT OUTER JOIN _TDADept AS D ON D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq
     LEFT OUTER JOIN (SELECT ppsregseq,  
                             SUM(ISNULL(Qty,0)) AS OutQty,  
                             SUM(ISNULL(CurAmt,0) + ISNULL(CurVat,0)) AS OutAmt  
                     FROM hencom_VIEWPreSalesResult  
                     WHERE CompanySeq = @CompanySeq   
                     AND ppsregseq <> 0  
                     GROUP BY ppsregseq  
                     ) AS O ON O.PPSRegSeq = A.PPSRegSeq  
        
     WHERE A.CompanySeq = @CompanySeq      
     AND A.DeptSeq = @Param1          
     AND A.CustSeq = @Param2  
     --AND A.ItemSeq = @Param3 -- 2017.02.10 �߰� , 2017.04.26 �ּ�
     AND B.ItemName = @ItemName -- 2017.04.26 �߰� 
     --AND A.PJTSeq = @Param3      

         
     SET @SELECTSQL = 'SELECT * FROM  #TMPTable AS A'    
       IF @DefQueryOption = 0 --�������ù�ȣ    
     BEGIN    
         SET @WHERESQL = 'WHERE A.PublicSalesNo LIKE ''' + LTRIM(RTRIM(@Keyword)) + ''' '+ CHAR(13)      
     END    
     IF @DefQueryOption = 1 --�ŷ�ó    
     BEGIN    
         SET @WHERESQL =  'WHERE A.PPCustName LIKE ''' + LTRIM(RTRIM(@Keyword)) + ''' '+ CHAR(13)      
     END    
      IF @DefQueryOption = 2 --�԰�    
     BEGIN    
         SET @WHERESQL = 'WHERE A.PPItemName LIKE ''' + LTRIM(RTRIM(@Keyword)) + ''' '+ CHAR(13)      
     END    
       IF @DefQueryOption = 3 --����    
     BEGIN    
         SET @WHERESQL = 'WHERE A.PPPJTName LIKE ''' + LTRIM(RTRIM(@Keyword)) + ''' '+ CHAR(13)      
     END    
         
 --     IF ISNULL(@ConditionSeq,'') <> ''          
 --        BEGIN          
 --            SELECT @WHERESQL  = @WHERESQL + ' AND ' + LTRIM(RTRIM(@ConditionSeq)) + ' '+ CHAR(13)      
 --        END          
             
       SET @SQL = @SELECTSQL +' '+ @WHERESQL    
         
     SET ROWCOUNT @PageCount           
          
     EXEC SP_EXECUTESQL @SQL    
         
 --    SET ROWCOUNT 0             
     
     RETURN      
     /**********************************************************************************************************/
