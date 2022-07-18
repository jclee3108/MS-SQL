IF OBJECT_ID('KPXCM_SPDProdProcSubCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDProdProcSubCheck
GO 

-- v2016.03.07 
-- ��ǰ������ҿ���-��üũ by ���游
CREATE PROC KPXCM_SPDProdProcSubCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT
           ,@MaxSerl        INT
    CREATE TABLE #ProdProcRev (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#ProdProcRev'
    
	if  Exists(select 1 from #ProdProcRev where WorkingTag = 'A' )
	Begin
	    select @MaxSerl = max(A.Serl) 
		  from KPX_TPDProdProcItem AS A
              JOIN #ProdProcRev AS B ON B.ItemSeq = A.ItemSeq 
                                     ANd B.PatternRev = A.PatternRev
        
		Update #ProdProcRev
		   set Serl = isnull(@MaxSerl,0) + DataSeq
		 where  WorkingTag = 'A'
	end

    SELECT * FROM #ProdProcRev
RETURN

GO


