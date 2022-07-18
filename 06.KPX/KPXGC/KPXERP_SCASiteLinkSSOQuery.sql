IF OBJECT_ID('KPXERP_SCASiteLinkSSOQuery') IS NOT NULL 
    DROP PROC KPXERP_SCASiteLinkSSOQuery
GO 

-- v2015.06.02 

-- KPX����� �׷���� URL ���� 
/*************************************************************************************************/    
  
CREATE PROCEDURE KPXERP_SCASiteLinkSSOQuery    
/*************************************************************************************************    
 PROCEDURE   -   SGWMainSSoQuery(� DB)    
 FORM NAME   -   FrmMainUp    
 DESCRIPTION -   �׷���� ���� - ParamName, ParamValue�� Post�� Submit�Ѵ�.    
 ��  ��  ��  -   2008. 03. 28 : Created by ������    
 ��  ��  ��  -   2008. 03. 28 : Created by ������    
    
*************************************************************************************************/    
-- _SCASiteLinkSSOQuery '',2,18,1,1,'','','',,'','','','',''    
-- _SCASiteLinkSSOQuery '',9001007,18,1,1,'dev_bis','dev_oper','Slip',300254,'38797','','','','wellcomm|0||'    
    @WorkingTag     VARCHAR(5),    
    @LinkSeq        INT, -- SSO data ��Ϲ�ȣ    
    @UserSeq        INT,    
    @LanguageSeq    INT=1,    
    @CompanySeq     INT=1,    
    @GWDsn          NVARCHAR(40),    
    @GWDsnOper      NVARCHAR(40),    
    @GWWorkKind     NVARCHAR(40),    
    @GWPgmSeq       INT=1,    
    @GWValue1       NVARCHAR(100),    
    @GWValue2       NVARCHAR(100),    
    @GWValue3       NVARCHAR(100),    
    @GWValue4       NVARCHAR(100), -- EventType  GWView(1) else (0)    
    @GWDsnWell      NVARCHAR(100),    
    @LoginSeq       NVARCHAR(50) = '0'  
    , @GWErpNo      NVARCHAR(20) = N''  
    
AS    
    SET NOCOUNT ON    
    
    IF NOT EXISTS( SELECT 1 FROM _TCAUser WHERE UserSeq = @UserSeq)    
    BEGIN    
        SELECT '' AS Col1    
        RETURN    
    END    
    
    --����� ���� SSO Master Data    
     /*    
        *SSOType    
           41001    41  none    
           41002    41  cookie    
           41003    41  post    
           41004    41  get    
        *ContentType    
           42001    42  web    
           42002    42  exe    
        *ContainerType    
           43001    43  Genuine    
           43002    43  Explorer    
        *EncodingType  ��ȣȭ ����    
        *SecuParam     �Ķ��Ÿ�� �⺻��ȣȭ �Ǿ��� �������� ����    
    
    */    
    
    DECLARE @UserID    NVARCHAR(100),    
            @LoginPwd  NVARCHAR(200),    
            @DocID     NVARCHAR(100),    
            @LinkPath  NVARCHAR(300),    
            @TblTitle  NVARCHAR(200),    
            @ChIdx     INT,    
            @EmpSeq    INT,    
            @DeptID    NVARCHAR(100),    
            @SiteInit  NVARCHAR(100),    
            @NextUrl   NVARCHAR(100),    
            @SiteSPNM  NVARCHAR(100),    
            @DocState  NVARCHAR(100)    
    
    --=================================================================================================    
    --Site sp�� �ִٸ� ��� ����Ѵ�.    
    --2011-02-22 ������    
    --=================================================================================================    
    --SELECT @SiteSPNM  = ''    
    --SELECT @SiteSPNM = EnvValue + '_SCASiteLinkSSOQuery' FROM _TCOMEnv WHERE CompanySeq = @CompanySeq and EnvSeq = 2 -- Site �̴ϼ�    
    
    --IF @SiteSPNM <> '' AND EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = @SiteSPNM)    
    --BEGIN    
    
    --    EXEC @SiteSPNM @WorkingTag     ,@LinkSeq        ,@UserSeq        ,@LanguageSeq    ,@CompanySeq     ,    
    --         @GWDsn          ,@GWDsnOper      ,@GWWorkKind     ,@GWPgmSeq       ,@GWValue1       ,    
    --         @GWValue2       ,@GWValue3       ,@GWValue4       ,@GWDsnWell      ,@LoginSeq    
    --    RETURN    
    
    --END    
    --=================================================================================================    
    
    -- 2010�� 12�� 25�� �߰� : @GWValue4 ==> �������º��⿩�� + _/ + Tbl Title    
    SET @ChIdx = CHARINDEX('_/', @GWValue4, 1)    
    
    IF @ChIdx > 0    
    BEGIN    
        SET @TblTitle= SUBSTRING(@GWValue4, 4, LEN(@GWValue4))    
        SET @GWValue4= SUBSTRING(@GWValue4, 1, 1)    
    END    
    ELSE    
    BEGIN    
        SET @TblTitle = ''    
    END    
        
    -- 2010�� 12�� 25�� �߰� : @GWValue4 = '1' : ���� ������� ����    
    IF @GWValue4 = '1'    
    BEGIN    
  
          SELECT @LinkPath = RTRIM(ISNULL((SELECT TOP 1 A.EnvValue FROM _TCOMEnv A WITH(NOLOCK) WHERE A.CompanySeq = @CompanySeq AND A.EnvSeq = 9012), ''))    
    END    
    
    IF @LinkPath is null or @LinkPath = ''    
    BEGIN    
        SELECT @LinkPath = RTRIM(ISNULL((SELECT TOP 1 A.EnvValue  FROM _TCOMEnv A WITH(NOLOCK) WHERE A.CompanySeq = @CompanySeq AND A.EnvSeq = 9004), ''))    
    END    
    
    SELECT @LinkPath = RTRIM(ISNULL((SELECT TOP 1 A.EnvValue  FROM _TCOMEnv A WITH(NOLOCK) WHERE A.CompanySeq = @CompanySeq AND A.EnvSeq = 9002), '')) + @LinkPath    
    
    IF @LinkSeq = 9001001 -- ����    
    BEGIN    
        --CommonData(�׽�Ʈ ����϶� IsTest�÷��� �߰��ϸ� Submut���� �޽��� �ڽ��� ���´�.)    
        --SELECT '' IsTest,UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq    
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        SELECT  @LinkPath AS LinkPath,    
                '41003' SSOType,    
                '42001' ContentType,    
                '43002' ContainerType    
    
        SET @UserID = (SELECT UserId FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq)    
    
        --Post�� �ѱ涧 ����    
        SELECT  'MODE'          ParamName, 'WF'       ParamValue UNION    
        SELECT  'ConnInfo'      ParamName, 'wellcomm|0||'    ParamValue UNION    
        SELECT  'ConnInfoERP'   ParamName, @GWDsnOper+'|0||'   ParamValue UNION    
        SELECT  'Language'      ParamName, '0'        ParamValue UNION    
        SELECT  'UserID'        ParamName, @UserID      ParamValue UNION    
        SELECT  'WorkKind'      ParamName, @GWWorkKind     ParamValue UNION    
        SELECT  'TblKey'        ParamName, @GWValue1     ParamValue UNION    
        SELECT  'TblTitle'      ParamName, @TblTitle     ParamValue UNION    
        SELECT  'IsView'        ParamName, @GWValue4     ParamValue UNION    
        SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR,@GWPgmSeq) ParamValue    
    
    END    
    ELSE IF @LinkSeq = 9001002 -- �ȷ�-���¾���    
    BEGIN    
    
        --1.CommonData    
        --SELECT '' IsTest, UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq    
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        --2.SSO Master Data    
        SELECT @LinkPath AS LinkPath,    
               '41003' SSOType,    
               '42001' ContentType,    
               '43002' ContainerType    
          
        --3.Post Params Data    
        SELECT @UserID   = UserId , @LoginPwd = LoginPwd FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        IF LTRIM(RTRIM(@GWValue4)) = '1' -- �������(DocID����)    
        BEGIN    
            SELECT @DocID = DocID FROM _TCOMGroupWare WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkKind = @GWWorkKind AND TblKey = @GWValue1    
            SELECT 'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq       ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn         ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper     ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq   ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID        ) ParamValue, '1' EncodingType, '0' SecuParam UNION    
            SELECT 'LoginPwd'      ParamName, CONVERT(NVARCHAR(200),@GWValue3      ) ParamValue, '1' EncodingType, '1' SecuParam UNION    
            SELECT 'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
  
           SELECT 'PgmSeq'         ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'DocID'         ParamName, CONVERT(NVARCHAR(100),@DocID         ) ParamValue, '0' EncodingType, '0' SecuParam UNION -- �߰�(+)    
            SELECT 'CurrDateTime'  ParamName, CONVERT(VARCHAR, GetDate(), 120 ) ParamValue, '1' EncodingType, '0' SecuParam    
        END    
        ELSE -- �������ΰ��(DocID����)    
        BEGIN    
            SELECT @DocID = ''    
            SELECT 'LinkSeq'        ParamName, CONVERT(NVARCHAR(100),@LinkSeq       ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'Dsn'            ParamName, CONVERT(NVARCHAR(100),@GWDsn         ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'DsnOper'        ParamName, CONVERT(NVARCHAR(100),@GWDsnOper     ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'CompanySeq'     ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'LanguageSeq'    ParamName, CONVERT(NVARCHAR(100),@LanguageSeq   ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'UserID'         ParamName, CONVERT(NVARCHAR(100),@UserID        ) ParamValue, '1' EncodingType, '0' SecuParam UNION    
            SELECT 'LoginPwd'       ParamName, CONVERT(NVARCHAR(200),@GWValue3      ) ParamValue, '1' EncodingType, '1' SecuParam UNION    
            SELECT 'WorkKind'       ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'PgmSeq'         ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblKey'         ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblTitle'       ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'CurrDateTime'   ParamName, CONVERT(VARCHAR, GetDate(), 120 ) ParamValue, '1' EncodingType, '0' SecuParam    
        END    
    END    
    ELSE IF @LinkSeq = 9001003 -- ���������̽�    
    BEGIN    
    
        --1.CommonData    
 -- SELECT '' IsTest, UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq  
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        --2.SSO Master Data    
        SELECT  @LinkPath AS LinkPath,    
                '41003' SSOType,    
                '42001' ContentType,    
                '43002' ContainerType    
    
        SELECT @UserID = (SELECT UserId FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq)    
    
  ----http://gw.arion.co.kr/DeskPlusEIP/Site/Auth/LegacyLogin.aspx?userid=deskplus&nickname=LegacyHoli&parametc=1,2014-02-12 15:48:04,arion_bis,arion_oper,1,9001003,8245  
  
        --3.Post Params Data    
        SELECT  'UserID'            ParamName, CONVERT(NVARCHAR(100),@UserID        ) ParamValue UNION    
        SELECT  'WorkKind'          ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue UNION    
        SELECT  'TblKey'         ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue UNION    
        SELECT  'TblTitle'          ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue UNION   
  
        SELECT  'Parametc'   ParamName, CONVERT(NVARCHAR(100), @CompanySeq) + ',' +   
              CONVERT(VARCHAR, GetDate(), 120 ) + ',' +   
              @GWDsn + ',' + @GWDsnOper +',' + CONVERT(NVARCHAR(100), @LanguageSeq) + ',' +   
  
                CONVERT(NVARCHAR(100), @LinkSeq) + ',' + '' + ',' + CONVERT(NVARCHAR(100), @GWPgmSeq ) ParamValue UNION  
  SELECT  'ErpNum'            ParamName, CONVERT(NVARCHAR(100),DB_NAME()      ) ParamValue  
  
        -------- LegacyParmsEtc�� CompanySeq, ����ð�, ����DB��, �DB��, ����ڵ�, �׷�����ü�ڵ�, ����ھ�ȣ, ����ȭ���ڵ�     
       
     ----SELECT  'userId'           ParamName, CONVERT(NVARCHAR(100),@UserID        ) ParamValue UNION    
     ----   SELECT  'NickName'          ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue UNION    
     ----   SELECT  'legacyKey'         ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue UNION    
     ----   SELECT  'TblTitle'          ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue UNION    
     ----   SELECT  'LegacyParmsEtc'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue UNION  -- LegacyParmsEtc�� CompanySeq��.    
     ----   SELECT  'ErpNum'            ParamName, CONVERT(NVARCHAR(100),DB_NAME()      ) ParamValue    
       
    END    
  
    ELSE IF @LinkSeq = 9001005 -- ����    
    BEGIN    
    
        SET @UserID = (SELECT UserId FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq)    
        --1.CommonData    
        SELECT '' IsTest, UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq    
        --SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
  
        -- �������� ��������� �¿�� ���� ����Ʈ�̴ϼ� Ȯ��.  
        SELECT @SiteInit = EnvValue  FROM _TCOMEnv WHERE CompanySeq = @CompanySeq and EnvSeq = 2  
  
        IF @GWWorkKind = 'Slip' AND LTRIM(RTRIM(@GWValue4)) <> '1' AND @SiteInit = 'evdm' -- ������  
        BEGIN    
            SET @LinkPath = RTRIM(ISNULL((SELECT TOP 1 A.EnvValue FROM _TCOMEnv A WITH(NOLOCK) WHERE A.CompanySeq = 1 AND A.EnvSeq = 9002), '')) +   
                            RTRIM(ISNULL((SELECT TOP 1 A.EnvValue FROM _TCOMEnv A WITH(NOLOCK) WHERE A.CompanySeq = 1 AND A.EnvSeq = 9004), '')) +  
                            '?UserId=' + @UserID + '&Pwd=' + '&Lang=ko&EAID=153&CompanySeq=' +    
                CONVERT(VARCHAR, @CompanySeq) + '&LanguageSeq=' +    
                CONVERT(VARCHAR, @LanguageSeq) + '&UserSeq=' +    
                CONVERT(VARCHAR, @UserSeq) + '&PgmSeq=3093&WorkKind=Slip&TblKey=' +    
                @GWValue1 + '&SiteInit=1&NextUrl=/_EAPP/EADocumentWrite.aspx?FormID=153&ErpDocTitle='    
                  
            SET @LinkPath = REPLACE(@LinkPath, '/Genuine/', '/Public/')    
        END    
  
        --2.SSO Master Data    
        SELECT  @LinkPath AS LinkPath,    
                '41004' SSOType,    
                '42001' ContentType,    
                '43002' ContainerType    
    
        --3.Post Params Data    
        SELECT @UserID   = UserId ,    
               @LoginPwd = LoginPwd    
         FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        SELECT @DeptID = ISNULL(C.AbrDeptName, '')    
          FROM _TDAEmpIn AS A WITH(NOLOCK)    
               JOIN _THRAdmOrdEmp AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                   AND A.EmpSeq     = B.EmpSeq    
                                                   AND B.OrdDate    <  A.RetireDate    -- �������� �����߷ɱ���    
                                                   AND B.OrdDate    <= CASE WHEN ISNULL(A.RetireDate, '') > CONVERT(NCHAR(8),GETDATE(), 112) THEN CONVERT(NCHAR(8),GETDATE(), 112)    
                                                                            ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(A.RetireDate, '')), 112) END    
                                                   AND B.OrdEndDate >= CASE WHEN ISNULL(A.RetireDate, '') > CONVERT(NCHAR(8),GETDATE(), 112) THEN CONVERT(NCHAR(8),GETDATE(), 112)     
                                                                            ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(A.RetireDate, '')), 112) END    
                                                   AND B.IsOrdDateLast = '1'    
  
                 JOIN _TDADept AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                              AND B.DeptSeq    = C.DeptSeq    
         WHERE A.CompanySeq = @CompanySeq    
           AND A.EmpSeq     = @EmpSeq    
    
    
        --�ǿ����ؿ��� �������ڰ� �ؼ� ���� �ߴٰ���    
        --SELECT  'EAID'          ParamName, '71'          ParamValue UNION    
        --SELECT  'window'        ParamName, '1'          ParamValue UNION    
    
        IF LTRIM(RTRIM(@GWValue4)) = '1' -- �������(DocID����)    
        BEGIN    
            -- GroupKey���� �߰�. 20110104. �۳�ȯ    
            --�׷�Ű�� GROUP�� �����ϴ� Ű�� �����Ͽ� �����Ѵ�.    
            IF LEFT(@GWValue1,5) = 'GROUP'    
            BEGIN    
                SET @DocID = ISNULL((SELECT DISTINCT DocID FROM _TCOMGroupWare WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkKind = @GWWorkKind AND GroupKey = @GWValue1), '')  -->> ���ڰ��繮�� �޾ƿ��� �κ�    
            END    
            ELSE    
            BEGIN    
                SET @DocID = ISNULL((SELECT DocID FROM _TCOMGroupWare WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkKind = @GWWorkKind AND TblKey = @GWValue1), '')  -->> ���ڰ��繮�� �޾ƿ��� �κ�    
            END    
    
            SET @NextUrl ='%2f_EAPP%2fEADocumentView.aspx%3fDocID%3d'+ @DocID +'%26Window%3d1'    
    
            SET @LoginPwd = ''    
            -- EAID=0&Messenger=1&lang=ko&UserID=admin&Pwd=&    
            --SELECT  'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq        ) ParamValue UNION    
            --SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION    
            --SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION    
            --SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq     ) ParamValue UNION    
            --SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION    
            --SELECT  'LoginPwd'      ParamName, CONVERT(NVARCHAR(100),@LoginPwd       ) ParamValue UNION    
            --SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue UNION    
            --SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION    
            --SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1       ) ParamValue UNION    
            --SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue UNION    
            -- SELECT  'CurrDateTime'  ParamName, REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GetDate(), 120),' ',''),'-',''),':','') ParamValue    
            SELECT  'EAID'   ParamName, '0' ParamValue UNION    
            SELECT  'Messenger'     ParamName, '1' ParamValue UNION    
            SELECT  'lang'   ParamName, CONVERT(NVARCHAR(100),'ko'    ) ParamValue UNION    
            SELECT  'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue UNION    
            SELECT  'Pwd'   ParamName, CONVERT(NVARCHAR(200),@LoginPwd       ) ParamValue UNION    
            SELECT  'NextUrl'  ParamName, CONVERT(NVARCHAR(100), @NextUrl) ParamValue    
    
        END    
        ELSE    
        BEGIN    
            IF @GWWorkKind = 'Slip' AND @SiteInit = 'evdm'  
            BEGIN    
                SET @NextUrl ='%2f_EAPP%EADocumentWrite.aspx%3fFormID%3d'+ '153ErpDocTitle%3d'    
    
                SELECT  'UserIDaaa'       ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue    
                --SELECT  'Pwd'           ParamName, CONVERT(NVARCHAR(100),@LoginPwd       ) ParamValue UNION    
                --SELECT  'Lang'          ParamName, CONVERT(NVARCHAR(100),'ko'    ) ParamValue UNION    
                --SELECT  'EAID'          ParamName, '153' ParamValue UNION    
                --SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq     ) ParamValue UNION    
                --SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION    
  
                  --SELECT  'UserSeq'       ParamName, CONVERT(NVARCHAR(100),@UserSeq         ) ParamValue UNION    
                --SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION    
                --SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue UNION    
                --SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1       ) ParamValue UNION    
                --SELECT  'NextUrl'       ParamName, CONVERT(NVARCHAR(100), @NextUrl) ParamValue    
            END    
            ELSE    
            BEGIN    
                SELECT  'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq        ) ParamValue UNION    
                SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION    
                SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION    
                SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq     ) ParamValue UNION    
                SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION    
                SELECT  'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue UNION    
                --SELECT  'LoginPwd'      ParamName, CONVERT(NVARCHAR(200),@LoginPwd       ) ParamValue UNION    
                SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue UNION    
                SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION    
                SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1       ) ParamValue UNION    
                SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue UNION    
                SELECT  'CurrDateTime'  ParamName, REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GetDate(), 120),' ',''),'-',''),':','') ParamValue    
            END    
        END    
    END    
    ELSE IF @LinkSeq = 9001008 -- �¼�    
    BEGIN    
        --1.CommonData(�׽�Ʈ ����϶� IsTest�÷��� �߰��ϸ� Submut���� �޽��� �ڽ��� ���´�.)    
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        --2.SSO Master Data    
        SELECT  @LinkPath AS LinkPath,    
                '41003' SSOType,    
                '42001' ContentType,                  '43002' ContainerType    
    
        SELECT @SiteInit = ISNULL(EnvValue,'')    
          FROM _TCOMENV    
         WHERE CompanySeq = @CompanySeq    
           AND EnvSeq     = 2    
    
        --3.Post Params Data    
         SELECT @UserID   = UserId ,    
                @LoginPwd = LoginPwd,    
                @EmpSeq   = EmpSeq    
          FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        SELECT @DeptID = ISNULL(C.AbrDeptName, '')    
          FROM _TDAEmpIn AS A WITH(NOLOCK)    
               JOIN _THRAdmOrdEmp AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                   AND A.EmpSeq     = B.EmpSeq    
                                                   AND B.OrdDate    <  A.RetireDate    -- �������� �����߷ɱ���    
                                                   AND B.OrdDate    <= CASE WHEN ISNULL(A.RetireDate, '') > CONVERT(NCHAR(8),GETDATE(), 112) THEN CONVERT(NCHAR(8),GETDATE(), 112) ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(A.RetireDate, '')), 112) END     
    
                                                   AND B.OrdEndDate >= CASE WHEN ISNULL(A.RetireDate, '') > CONVERT(NCHAR(8),GETDATE(), 112) THEN CONVERT(NCHAR(8),GETDATE(), 112) ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(A.RetireDate, '')), 112) END     
    
                                                   AND B.IsOrdDateLast = '1'    
               JOIN _TDADept AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                              AND B.DeptSeq    = C.DeptSeq    
         WHERE A.CompanySeq = @CompanySeq    
             AND A.EmpSeq     = @EmpSeq    
  
    
        SELECT 'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq       ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn         ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper     ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Lang'          ParamName, CONVERT(NVARCHAR(100),'KOR'          ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'GMT'           ParamName, CONVERT(NVARCHAR(100),'9'            ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID        ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'UserPwd'       ParamName, CONVERT(NVARCHAR(200),@GWValue3      ) ParamValue, '1' EncodingType, '1' SecuParam UNION    
        SELECT 'formERPID'     ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'ERPKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'DeptID'        ParamName, CONVERT(NVARCHAR(100),@DeptID        ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'VarTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param0'        ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param1'        ParamName, CONVERT(NVARCHAR(100),@LanguageSeq   ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param2'        ParamName, CONVERT(NVARCHAR(100),@UserSeq       ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param3'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param4'        ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param5'        ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param6'        ParamName, CONVERT(NVARCHAR(100),@SiteInit      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'DocID'         ParamName, CONVERT(NVARCHAR(100),@DocID         ) ParamValue, '0' EncodingType, '0' SecuParam UNION -- �߰�(+)    
        SELECT 'CurrDateTime'  ParamName, CONVERT(VARCHAR, GetDate(), 120 ) ParamValue, '1' EncodingType, '0' SecuParam    
    END    
        
    -- 2011.02.28 ������ũ�߰�    
    ELSE IF @LinkSeq = 9001007 -- ������ũ    
    BEGIN    
        --1.CommonData(�׽�Ʈ����϶�IsTest�÷����߰��ϸ�Submut�����޽����ڽ������´�.)    
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq    
        
        --2.SSO Master Data    
        SELECT  (SELECT TOP 1 A.EnvValue FROM _TCOMEnv A WHERE A.CompanySeq = @CompanySeq AND A.EnvSeq = 9002) +    
                (SELECT TOP 1 A.EnvValue FROM _TCOMEnv A WHERE A.CompanySeq = @CompanySeq AND A.EnvSeq = 9004) LinkPath,    
                '41004' SSOType,    
                '42001' ContentType,    
                '43002' ContainerType    
        
        --3.Post Params Data    
        SELECT @UserID   = UserId ,    
               @LoginPwd = LoginPwd    
          FROM _TCAUser WHERE UserSeq = @UserSeq    
        
        SELECT  'LinkSeq'       ParamName, CONVERT(NVARCHAR,@LinkSeq        ) ParamValue UNION    
          SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR,@GWDsn           ) ParamValue UNION    
  
        SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR,@GWDsnOper      ) ParamValue UNION    
        SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR,@CompanySeq     ) ParamValue UNION    
        SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR,@LanguageSeq    ) ParamValue UNION    
        SELECT  'UserID'        ParamName, CONVERT(NVARCHAR,@UserID         ) ParamValue UNION    
        --SELECT  'LoginPwd'      ParamName, CONVERT(NVARCHAR,@LoginPwd       ) ParamValue UNION     (����)    
        SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR,@GWWorkKind     ) ParamValue UNION    
        SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR,@GWPgmSeq       ) ParamValue UNION    
        SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR,@GWValue1       ) ParamValue UNION    
        SELECT  'CurrDateTime'  ParamName, REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GetDate(), 120),' ',''),'-',''),':','') ParamValue    
    END    
    ELSE IF @LinkSeq = 9001008 -- �¼�    
    BEGIN    
        --1.CommonData(�׽�Ʈ ����϶� IsTest�÷��� �߰��ϸ� Submut���� �޽��� �ڽ��� ���´�.)    
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        --2.SSO Master Data    
        SELECT  @LinkPath AS LinkPath,    
                '41003' SSOType,    
                '42001' ContentType,    
                '43002' ContainerType    
    
        SELECT @SiteInit = ISNULL(EnvValue,'')    
          FROM _TCOMENV    
         WHERE CompanySeq = @CompanySeq    
           AND EnvSeq     = 2    
    
        --3.Post Params Data    
        SELECT @UserID   = UserId ,    
               @LoginPwd = LoginPwd,    
               @EmpSeq   = EmpSeq    
         FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        SELECT @DeptID = ISNULL(C.AbrDeptName, '')    
          FROM _TDAEmpIn AS A WITH(NOLOCK)    
               JOIN _THRAdmOrdEmp AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                   AND A.EmpSeq     = B.EmpSeq    
                                                   AND B.OrdDate    <  A.RetireDate    -- �������� �����߷ɱ���    
                                                   AND B.OrdDate    <= CASE WHEN ISNULL(A.RetireDate, '') > CONVERT(NCHAR(8),GETDATE(), 112) THEN CONVERT(NCHAR(8),GETDATE(), 112)     
                                                                            ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(A.RetireDate, '')), 112) END    
                                                   AND B.OrdEndDate >= CASE WHEN ISNULL(A.RetireDate, '') > CONVERT(NCHAR(8),GETDATE(), 112) THEN CONVERT(NCHAR(8),GETDATE(), 112)     
                                                                            ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(A.RetireDate, '')), 112) END    
                                                   AND B.IsOrdDateLast = '1'    
               JOIN _TDADept AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                              AND B.DeptSeq    = C.DeptSeq    
         WHERE A.CompanySeq = @CompanySeq    
           AND A.EmpSeq     = @EmpSeq    
    
        SELECT 'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq       ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn         ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper     ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Lang'          ParamName, CONVERT(NVARCHAR(100),'KOR'          ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'GMT'           ParamName, CONVERT(NVARCHAR(100),'9'            ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
  
          SELECT 'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'UserPwd'       ParamName, CONVERT(NVARCHAR(200),@GWValue3      ) ParamValue, '1' EncodingType, '1' SecuParam UNION    
        SELECT 'formERPID'     ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'ERPKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'DeptID'        ParamName, CONVERT(NVARCHAR(100),@DeptID        ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'VarTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param0'        ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param1'        ParamName, CONVERT(NVARCHAR(100),@LanguageSeq   ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param2'        ParamName, CONVERT(NVARCHAR(100),@UserSeq       ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param3'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param4'        ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param5'        ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'Param6'        ParamName, CONVERT(NVARCHAR(100),@SiteInit      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
        SELECT 'DocID'         ParamName, CONVERT(NVARCHAR(100),@DocID         ) ParamValue, '0' EncodingType, '0' SecuParam UNION -- �߰�(+)    
        SELECT 'CurrDateTime'  ParamName, CONVERT(VARCHAR, GetDate(), 120 ) ParamValue, '1' EncodingType, '0' SecuParam    
    END    
    ELSE IF @LinkSeq = 90010010 -- ���¾���-ǥ��(KBSN ���� �� �۾����� ����)    
    BEGIN    
        --_SCASiteLinkSSOQuery '',90010010,1,1,1,'kbsn_bis','kbsn_oper','EDUPers',7663,'3','','/HWTbwDKrDA=','0_/','wellcomm|0||','895'    
        --1.CommonData    
        --SELECT '' IsTest, UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq    
        SELECT  UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
          
        --2.SSO Master Data    
        SELECT @LinkPath AS LinkPath,    
               '41003' SSOType,    
            '42001' ContentType,    
               '43002' ContainerType    
          
        --3.Post Params Data    
        SELECT @UserID   = UserId , @LoginPwd = LoginPwd FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
          
        --select * from c    
        DECLARE @SecuParam VARCHAR(1)    
          
        IF @UserSeq = 1    
        BEGIN    
            SET @SecuParam = '1'    
        END    
        ELSE    
        BEGIN    
            SET @SecuParam = '1'    
        END    
          
        -- Loginpwd=111,UserID=gisa1    
        IF LTRIM(RTRIM(@GWValue4)) = '1' -- �������(DocID����)    
        BEGIN    
            SELECT @DocID = DocID FROM _TCOMGroupWare WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkKind = @GWWorkKind AND TblKey = @GWValue1    
            SELECT @DocState = (CASE WHEN (IsProg = 0 AND IsEnd = 0) THEN 'APR'  -- �ݼ�ó���� APR�� ó���ȴٰ���.    
                                     WHEN (IsProg = 1 AND IsEnd = 0) THEN 'APR'    
                                     WHEN (IsProg = 1 AND IsEnd = 1) THEN 'END' ELSE '' END)    
              FROM _TCOMGroupWare WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkKind = @GWWorkKind AND TblKey = @GWValue1    
                  
  
              SELECT 'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq        ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn         ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper     ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq   ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID        ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'LoginPwd'      ParamName, CONVERT(NVARCHAR(200),@GWValue3      ) ParamValue, '0' EncodingType, @SecuParam SecuParam UNION    
            SELECT 'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'DocID'         ParamName, CONVERT(NVARCHAR(100),@DocID         ) ParamValue, '0' EncodingType, '0' SecuParam UNION -- �߰�(+)    
            SELECT 'docstate'      ParamName, CONVERT(NVARCHAR(100),@DocState      ) ParamValue, '0' EncodingType, '0' SecuParam UNION -- �߰�(+)    
            SELECT 'CurrDateTime'  ParamName, CONVERT(VARCHAR, GetDate(), 120 ) ParamValue, '1' EncodingType, '0' SecuParam    
        END    
        ELSE -- �������ΰ��(DocID����)    
        BEGIN    
          
            SELECT @DocID = ''    
            SELECT 'LinkSeq'        ParamName, CONVERT(NVARCHAR(100),@LinkSeq       ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'Dsn'            ParamName, CONVERT(NVARCHAR(100),@GWDsn         ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'DsnOper'        ParamName, CONVERT(NVARCHAR(100),@GWDsnOper     ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'CompanySeq'     ParamName, CONVERT(NVARCHAR(100),@CompanySeq    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'LanguageSeq'    ParamName, CONVERT(NVARCHAR(100),@LanguageSeq   ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'UserID'         ParamName, CONVERT(NVARCHAR(100),@UserID        ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'LoginPwd'       ParamName, CONVERT(NVARCHAR(200),@GWValue3      ) ParamValue, '0' EncodingType, @SecuParam SecuParam UNION    
            SELECT 'WorkKind'       ParamName, CONVERT(NVARCHAR(100),@GWWorkKind    ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'PgmSeq'         ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblKey'         ParamName, CONVERT(NVARCHAR(100),@GWValue1      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'TblTitle'       ParamName, CONVERT(NVARCHAR(100),@TblTitle      ) ParamValue, '0' EncodingType, '0' SecuParam UNION    
            SELECT 'CurrDateTime'   ParamName, CONVERT(VARCHAR, GetDate(), 120 ) ParamValue, '1' EncodingType, '0' SecuParam    
        END    
    END    
    ELSE IF @LinkSeq = 9001910 -- ������-���ڰ���    
    BEGIN    
        --CommonData(�׽�Ʈ ����϶� IsTest�÷��� �߰��ϸ� Submut���� �޽��� �ڽ��� ���´�.)    
        --SELECT '' IsTest,UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq    
          SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
   SELECT  @LinkPath AS LinkPath,    
                '41003' SSOType,    
                '42001' ContentType,    
                '43002' ContainerType    
  
        IF LTRIM(RTRIM(@GWValue4)) = '1' -- �������(DocID����)    
        BEGIN    
            SELECT  'LoginSeq'      ParamName, @LoginSeq                               ParamValue UNION    
            SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION    
            SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION    
            SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION    
            SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION    --// 20121122 ������ PgmSeq �߰�  
            SELECT  'MoveKind'      ParamName, 'VIEW'                                  ParamValue UNION    
            SELECT  'WorkKind'      ParamName, @GWWorkKind                             ParamValue UNION    
            SELECT  'TblKey'        ParamName, @GWValue1                               ParamValue UNION   
            SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue  
        END    
        ELSE    
        BEGIN    
            SELECT  'LoginSeq'      ParamName, @LoginSeq                               ParamValue UNION    
            SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION    
            SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION    
            SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION    
            SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION    --// 20121122 ������ PgmSeq �߰�  
            SELECT  'MoveKind'      ParamName, 'REG'                                   ParamValue UNION    
            SELECT  'WorkKind'      ParamName, @GWWorkKind                             ParamValue UNION    
            SELECT  'TblKey'        ParamName, @GWValue1                               ParamValue UNION  
            SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue UNION  
            SELECT  'ErpNo'         ParamName, @GWErpNo                                ParamValue  
        END    
    END    
    ELSE IF @LinkSeq = 90010011 -- ���¼���Ʈ. 2011.10.02. nhsong �߰�.    
    BEGIN      
        --CommonData(�׽�Ʈ ����϶� IsTest�÷��� �߰��ϸ� Submut���� �޽��� �ڽ��� ���´�.)      
        --SELECT '' IsTest,UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WHERE UserSeq = @UserSeq      
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq      
      
        SELECT  @LinkPath AS LinkPath,      
                '41003' SSOType,      
                '42001' ContentType,      
                '43002' ContainerType      
    
        --3.Post Params Data      
         SELECT @UserID   = UserId ,      
                @LoginPwd = LoginPwd      
          FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq      
                
        IF LTRIM(RTRIM(@GWValue4)) = '1' -- �������(DocID����)      
        BEGIN      
            SELECT  'app_type'      ParamName, '1'                                     ParamValue UNION      
            SELECT  'cmd'           ParamName, 'secERPDraft'                           ParamValue UNION      
            SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq     ) ParamValue UNION      
            SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION      
            SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION      
            SELECT  'form_id'       ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue UNION      
              SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION      
    SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION      
            SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1       ) ParamValue UNION      
            SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue UNION      
            SELECT  'user_id'       ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue UNION      
            SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue       
        END      
        ELSE  -- ������    
        BEGIN    
            SELECT  'app_type'      ParamName, '1'                                     ParamValue UNION      
            SELECT  'cmd'           ParamName, 'secERPDraft'                           ParamValue UNION      
            SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq     ) ParamValue UNION      
            SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION      
            SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION      
            SELECT  'form_id'       ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue UNION      
            SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION      
            SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION      
            SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1       ) ParamValue UNION      
            SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue UNION      
            SELECT  'user_id'       ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue UNION      
            SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue       
        END      
    END      
    ELSE IF @LinkSeq = 9001006 -- ������ (    
    BEGIN    
        --1.CommonData(�׽�Ʈ ����϶� IsTest�÷��� �߰��ϸ� Submut���� �޽��� �ڽ��� ���´�.)            
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq            
             
        --2.SSO Master Data            
        SELECT  @LinkPath AS LinkPath,            
                '41004' SSOType, -- get�� ������(escapeó���� �ȵǾ...), post�� ������    
                '42001' ContentType,            
                '43002' ContainerType            
             
        --3.Post Params Data            
        SELECT @UserID   = UserId ,            
                @LoginPwd = LoginPwd            
        FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq          
             
        SELECT  'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq        ) ParamValue UNION            
        SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION            
        SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION            
        SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq     ) ParamValue UNION          
        SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION            
        SELECT  'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue UNION            
        --SELECT  'LoginPwd'      ParamName, CONVERT(NVARCHAR(100),@LoginPwd       ) ParamValue UNION            
        SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue UNION            
        SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION            
        SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1       ) ParamValue UNION            
        SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue UNION            
  
          SELECT  'CurrDateTime'  ParamName, REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GetDate(), 120),' ',''),'-',''),':','') ParamValue     
    END    
    ELSE    -- �⺻��    
    BEGIN    
        --1.CommonData(�׽�Ʈ ����϶� IsTest�÷��� �߰��ϸ� Submut���� �޽��� �ڽ��� ���´�.)    
        SELECT UserId, UserName, PwdMailAdder AS MailAddress FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        --2.SSO Master Data    
        SELECT  @LinkPath AS LinkPath,    
                '41003' SSOType, -- get�� ������(escapeó���� �ȵǾ...), post�� ������    
                '42001' ContentType,    
                '43002' ContainerType    
    
        --3.Post Params Data    
         SELECT @UserID   = UserId ,    
                @LoginPwd = LoginPwd    
          FROM _TCAUser WITH(NOLOCK) WHERE UserSeq = @UserSeq    
    
        SELECT @DocID = DocID FROM _TCOMGroupWare WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkKind = @GWWorkKind AND TblKey = @GWValue1  
  
        SELECT  'LinkSeq'       ParamName, CONVERT(NVARCHAR(100),@LinkSeq        ) ParamValue UNION    
        SELECT  'Dsn'           ParamName, CONVERT(NVARCHAR(100),@GWDsn          ) ParamValue UNION    
        SELECT  'DsnOper'       ParamName, CONVERT(NVARCHAR(100),@GWDsnOper      ) ParamValue UNION    
        SELECT  'CompanySeq'    ParamName, CONVERT(NVARCHAR(100),@CompanySeq     ) ParamValue UNION    
        SELECT  'LanguageSeq'   ParamName, CONVERT(NVARCHAR(100),@LanguageSeq    ) ParamValue UNION    
        SELECT  'UserID'        ParamName, CONVERT(NVARCHAR(100),@UserID         ) ParamValue UNION    
        SELECT  'LoginPwd'      ParamName, CONVERT(NVARCHAR(200),@GWValue3       ) ParamValue UNION    
        SELECT  'WorkKind'      ParamName, CONVERT(NVARCHAR(100),@GWWorkKind     ) ParamValue UNION    
        SELECT  'PgmSeq'        ParamName, CONVERT(NVARCHAR(100),@GWPgmSeq       ) ParamValue UNION    
        SELECT  'TblKey'        ParamName, CONVERT(NVARCHAR(100),@GWValue1       ) ParamValue UNION    
        SELECT  'TblTitle'      ParamName, CONVERT(NVARCHAR(100),@TblTitle       ) ParamValue UNION  
        SELECT  'DocID'         ParamName, CONVERT(NVARCHAR(100),@DocID          ) ParamValue UNION  
        SELECT  'CurrDateTime'  ParamName, REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GetDate(), 120),' ',''),'-',''),':','') ParamValue    
    END    
RETURN  
  