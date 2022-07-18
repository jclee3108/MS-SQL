  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHEQuerySub') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHEQuerySub  
GO  
  
-- v2014.12.12  
  
-- �������輺�򰡵��-��������ȸ by ����õ   
CREATE PROC KPX_SEQChangeRiskRstCHEQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    SELECT 'I' AS F1, '18�ʰ� ~ 24' AS F2, 'HAZOP��� ��(����� �����м�)' AS F3
    UNION ALL
    SELECT 'II' AS F1, '12�ʰ� ~ 18����' AS F2, 'HAZOP��� ��(����� �����м�)' AS F3
    UNION ALL
    SELECT 'III' AS F1, '6�ʰ� ~ 12����' AS F2, 'CheckList��� ��' AS F3
    UNION ALL
    SELECT 'IV' AS F1, '1�ʰ� ~ 6����' AS F2, 'CheckList��� ��' AS F3
    
    RETURN  
GO
exec KPX_SEQChangeRiskRstCHEQuerySub @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1026700,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022351