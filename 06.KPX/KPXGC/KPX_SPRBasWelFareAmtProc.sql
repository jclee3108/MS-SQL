
IF OBJECT_ID('KPX_SPRBasWelFareAmtProc') IS NOT NULL 
    DROP PROC KPX_SPRBasWelFareAmtProc
GO 

-- v2014.12.09 

-- �����Ļ��޻�����ó�� by����õ 
CREATE PROCEDURE KPX_SPRBasWelFareAmtProc  
    @CompanySeq     INT,        -- �����ڵ�  
    @PbYm           NCHAR(6),   -- ������  
    @SMWelFareType  INT,        -- �����Ļ�����  
    @UserSeq        INT         -- �����    
    
AS           
    
    INSERT INTO _TPRBasWelFareAmt 
    (
        CompanySeq, PbYm, UMWelFareType, EmpSeq, PbSeq, Amt, LastUserSeq, LastDateTime
    )
    SELECT @CompanySeq, @PbYm, B.MinorSeq, A.EmpSeq, A.PbSeq, SUM(ISNULL(A.CompanyAmt,0)), @UserSeq, GETDATE()  
      FROM KPX_THRWelMediEmp AS A 
      OUTER APPLY ( SELECT TOP 1 Y.MinorSeq, Y.MinorName 
                      FROM _TDAUMinorValue AS Z 
                      LEFT OUTER JOIN _TDAUMinor   AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.MinorSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MajorSeq = 3004 
                       AND Z.Serl = 1001 
                       AND Z.ValueSeq = @SMWelFareType 
                  ) AS B 
     WHERE (1=1)  
       AND A.CompanySeq = @CompanySeq  
       AND A.PbYm = @PbYm  
       AND ISNULL(A.PbSeq,0) <> 0  
       AND ISNULL(B.MinorSeq,0) <> 0 
     GROUP BY A.EmpSeq, B.MinorSeq, A.PbSeq  
    
    RETURN      
