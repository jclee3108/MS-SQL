IF OBJECT_ID('mnpt_SCACodeHelpShipDetailQuery') IS NOT NULL 
    DROP PROC mnpt_SCACodeHelpShipDetailQuery
GO 

-- v2017.09.12

-- �������ڵ� �ڵ嵵�� by����õ
CREATE PROCEDURE mnpt_SCACodeHelpShipDetailQuery
	@WorkingTag     NVARCHAR(1),                    
    @LanguageSeq    INT,                    
    @CodeHelpSeq    INT,                    
    @DefQueryOption INT, -- 2: direct search                    
    @CodeHelpType   TINYINT,                    
    @PageCount      INT = 20,         
    @CompanySeq     INT = 1,                   
    @Keyword        NVARCHAR(50) = '',                    
    @Param1         NVARCHAR(50) = '',        
    @Param2         NVARCHAR(50) = '',        
    @Param3         NVARCHAR(50) = '',        
    @Param4         NVARCHAR(50) = ''        
AS     
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    
    SET ROWCOUNT @PageCount      
    
    SELECT A.ShipSeq           -- �𼱳����ڵ� 
          ,A.ShipSerl          -- ���������� 
          ,B.IFShipCode + '-' + STUFF(A.ShipSerlNo,5,0,'-') AS ShipSerlNo       -- ���� 
          ,B.IFShipCode        -- ���ڵ� 
          ,B.EnShipName        -- �𼱸�(����) 
          ,B.ShipName          -- �𼱸�(�ѱ�) 
          ,B.TotalTON          -- GRT(TON) 
          ,B.LOA               -- LOA 
          ,B.DRAFT             -- DRAFT 
          ,B.LINECode          -- LINE 
          ,STUFF(STUFF(LEFT(A.InPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.InPlanDateTime,4),3,0,':')   AS InPlanDateTime  -- ���׿����Ͻ�
          ,STUFF(STUFF(LEFT(A.OutPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.OutPlanDateTime,4),3,0,':') AS OutPlanDateTime -- ���׿����Ͻ�
          ,STUFF(STUFF(LEFT(A.InDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.InDateTime,4),3,0,':') AS InDateTime                -- �����Ͻ� 
          ,STUFF(STUFF(LEFT(A.ApproachDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ApproachDateTime,4),3,0,':') AS ApproachDateTime -- �����Ͻ�
          ,STUFF(STUFF(LEFT(A.WorkSrtDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.WorkSrtDateTime,4),3,0,':') AS WorkSrtDateTime -- �Ͽ������Ͻ�
          ,STUFF(STUFF(LEFT(A.WorkEndDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.WorkEndDateTime,4),3,0,':') AS WorkEndDateTime -- �Ͽ������Ͻ�
          ,STUFF(STUFF(LEFT(A.OutDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.OutDateTime,4),3,0,':') AS OutDateTime                -- �����Ͻ� 
          ,STUFF(STUFF(LEFT(A.OutDateTime,8),5,0,'-'),8,0,'-') AS OutDate -- ������ 
          -- ���Ƚð�(�ð������� �ø�) : (�����Ͻ�[DATETIME Ÿ��(������ ���)] - �����Ͻ�[DATETIME Ÿ��(������ ���)]) / 60. 
          , DiffApproachTime -- ���Ƚð�

          ,A.BERTH             -- ���� 
          ,A.BRIDGE            -- BRIDGE 
          ,A.FROM_BIT + '~' + A.TO_BIT AS BIT   -- BIT 
          ,A.PORT              -- ������PORT
          ,A.TRADECode         -- �׷� 
          ,CASE WHEN EXISTS (SELECT 1 FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 1015793 AND MinorName = A.TRADECode) 
                THEN '���׼�'
                WHEN ISNULL(A.TRADECode,'') = '' 
                THEN '' 
                ELSE '���׼�' 
                END AS TRADETypeName 
          ,F.MinorName AS BULKCNTR -- ��ũ�����̳ʱ���
          ,I.BizUnitName AS BizUnitName 
          ,A.AgentName          -- �븮�� 

      FROM mnpt_TPJTShipDetail              AS A   
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipSeq = A.ShipSeq ) 
      LEFT OUTER JOIN _TCAUser              AS D ON ( D.CompanySeq = @CompanySeq AND D.UserSeq = A.FirstUserSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E ON ( E.CompanySeq = @CompanySeq AND E.Majorseq = 1015786 AND E.Serl = 1000001 AND E.ValueText = A.BULKCNTR ) 
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS G ON ( G.CompanySeq = @CompanySeq AND G.Majorseq = 1015794 AND G.Serl = 1000001 AND G.ValueText = A.BizUnitCode ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq AND H.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDABizUnit           AS I ON ( I.CompanySeq = @CompanySeq AND I.BizUnit = H.ValueSeq ) 
	 WHERE A.CompanySeq	= @CompanySeq
	   AND ( (@DefQueryOption = '1' AND (@Keyword = '' OR B.IFShipCode + '-' + STUFF(A.ShipSerlNo,5,0,'-') LIKE @Keyword + '%')) 
          OR (@DefQueryOption = '2' AND (@Keyword = '' OR B.EnShipName LIKE @Keyword + '%')) 
          OR (@DefQueryOption = '3' AND (@Keyword = '' OR B.ShipName LIKE @Keyword + '%')) 
           ) 
       AND (@Param1 = '' OR A.ShipSeq = CONVERT(INT,@Param1))
    
    SET ROWCOUNT 0 
    
    return 
    GO


    exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'13820009',@Keyword=N'%%',@Param1=N'',@Param2=N'',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=1,@FactUnit=1,@DeptSeq=1,@WkDeptSeq=18,@EmpSeq=64,@UserSeq=167