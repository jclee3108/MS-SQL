
IF OBJECT_ID('KPX_SDAItemUserDefineCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemUserDefineCheck
GO 

-- v2014.11.04 

-- �߰�����üũ by����õ 

/*********************************************************************************************************************
     ȭ��� : ǰ���� - �߰�����üũ
     SP Name: _SDAItemUserDefineCheck
     �ۼ��� : 2009.10.27 : CREATEd by ������    
     ������ : 
 ********************************************************************************************************************/
 CREATE PROC KPX_SDAItemUserDefineCheck    
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,      
     @WorkingTag     NVARCHAR(10)= '',      
     @CompanySeq     INT = 1,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,      
     @PgmSeq         INT = 0      
     
 AS        
     
     DECLARE @Count       INT,    
             @Seq         INT,    
             @MessageType INT,    
             @Status      INT,    
             @Results     NVARCHAR(250)
     
     -- ���� ����Ÿ ��� ����    
     CREATE TABLE #KPX_TDAItemUserDefine (WorkingTag NCHAR(1) NULL)      
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemUserDefine'         
     IF @@ERROR <> 0 RETURN      
     
     
     -------------------------------------------    
     -- �ߺ�����üũ(��ȣ)    
     -------------------------------------------   
      
     -------------------------------------------    
     -- ����� WorkingTag����    
     -------------------------------------------    
      IF @WorkingTag = 'D' 
         UPDATE #KPX_TDAItemUserDefine
            SET WorkingTag = @WorkingTag
  
     UPDATE #KPX_TDAItemUserDefine    
     SET WorkingTag = 'A'     
     FROM #KPX_TDAItemUserDefine AS A     
         LEFT OUTER JOIN KPX_TDAItemUserDefine AS B ON B.CompanySeq = @CompanySeq  
                                                AND A.ItemSeq    = B.ItemSeq     
                                                AND A.MngSerl    = B.MngSerl     
     WHERE A.WorkingTag = 'U'     
       AND A.Status = 0          
       AND B.MngSerl IS NULL    
    
      
     SELECT * FROM #KPX_TDAItemUserDefine       
     RETURN        
GO 
