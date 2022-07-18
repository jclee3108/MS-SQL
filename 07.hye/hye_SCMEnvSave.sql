IF OBJECT_ID('HYE_SCMEnvSave') IS NOT NULL 
    DROP PROC HYE_SCMEnvSave
GO 

-- v2016.07.20 
       
 -- ȯ�漳��(����������)-���� by ����õ 
 CREATE PROC HYE_SCMEnvSave
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT     = 0,        
     @ServiceSeq     INT     = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
     @CompanySeq     INT     = 1,        
     @LanguageSeq    INT     = 1,        
     @UserSeq        INT     = 0,        
     @PgmSeq         INT     = 0        
 AS        
     CREATE TABLE #TCOMEnv (WorkingTag NCHAR(1) NULL)        
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TCOMEnv'        
     IF @@ERROR <> 0 RETURN        
           
     -- �α� �����          
     DECLARE @TableColumns NVARCHAR(4000)          
           
     -- Master �α�         
     SELECT @TableColumns = dbo._FGetColumnsForLog('HYE_TCOMEnvItem')          
           
     EXEC _SCOMLog @CompanySeq   ,              
                   @UserSeq      ,              
                   'HYE_TCOMEnvItem'    , -- ���̺��      -- JYO_TSLYearSalesPlanItemLog        
                   '#TCOMEnv'    , -- �ӽ� ���̺��              
                   'EnvSeq, EnvSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )              
                   @TableColumns, '', @PgmSeq  -- ���̺� ��� �ʵ��         
           
  
             
     -- DELETE          
     IF EXISTS (SELECT TOP 1 1 FROM #TCOMEnv WHERE WorkingTag = 'D' AND Status = 0)          
     BEGIN          
         DELETE HYE_TCOMEnvItem          
           FROM #TCOMEnv AS A          
           JOIN HYE_TCOMEnvItem AS B ON A.EnvSeq     = B.EnvSeq  
                                    AND A.EnvSerl    = B.EnvSerl  
           JOIN HYE_TCOMEnv     AS C ON B.EnvSeq     = C.EnvSeq  
                                    AND B.CompanySeq = C.CompanySeq  
          WHERE A.WorkingTag = 'D'          
            AND A.Status = 0          
            AND B.CompanySeq = @CompanySeq      
                  
         IF @@ERROR <> 0  RETURN          
     END          
             
     -- UPDATE          
     IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'U' AND Status = 0)          
     BEGIN          
                 
         UPDATE B          
            SET EnvValue        = A.EnvValue,          
                LastUserSeq     = @UserSeq,          
                LastDateTime    = GETDATE()          
           FROM #TCOMEnv         AS A    
           JOIN HYE_TCOMEnvItem  AS B ON A.EnvSeq     = B.EnvSeq   
                                     AND A.EnvSerl    = B.EnvSerl  
           JOIN HYE_TCOMEnv      AS C ON B.EnvSeq     = C.EnvSeq  
                                     AND B.CompanySeq = C.CompanySeq  
          WHERE A.WorkingTag = 'U'          
            AND A.Status = 0          
            AND B.CompanySeq = @CompanySeq          
                 
         IF @@ERROR <> 0  RETURN          
             
     END -- end if         
           
           
     -- INSERT          
     IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'A' AND Status = 0)          
     BEGIN          
         INSERT INTO HYE_TCOMEnvItem         
         (        
             CompanySeq, EnvSeq, EnvSerl, EnvValue, LastUserSeq, LastDateTime        
         )          
         SELECT @CompanySeq, EnvSeq, EnvSerl, EnvValue, @UserSeq, GETDATE()          
           FROM #TCOMEnv AS A          
          WHERE A.WorkingTag = 'A'          
            AND A.Status = 0          
              
         IF @@ERROR <> 0 RETURN          
     END          
           
     SELECT * FROM #TCOMEnv        
           
     RETURN 
GO


