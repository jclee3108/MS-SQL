if object_id('KPX_TACFundMaster') is null
begin 
CREATE TABLE KPX_TACFundMaster
(
    CompanySeq		INT 	 NOT NULL, 
    FundSeq		INT 	 NOT NULL, 
    FundName		NVARCHAR(100) 	 NOT NULL, 
    FundCode		NVARCHAR(100) 	 NOT NULL, 
    UMBond      INT NOT NULL, 
    BankSeq		INT 	 NOT NULL, 
    TitileName		NVARCHAR(100) 	 NULL, 
    FundKindM		INT 	 NOT NULL, 
    FundKindS		INT 	 NOT NULL, 
    ItemResult		NVARCHAR(100) 	 NULL, 
    BeforeRate		DECIMAL(19,5) 	 NULL, 
    FixRate		DECIMAL(19,5) 	 NULL, 
    Hudle		DECIMAL(19,5) 	 NULL, 
    Act		DECIMAL(19,5) 	 NULL, 
    SalesName		NVARCHAR(100) 	 NULL, 
    EmpName		NVARCHAR(100) 	 NULL, 
    ActCompany		NVARCHAR(100) 	 NULL, 
    BillCompany		NVARCHAR(100) 	 NULL, 
    SetupTypeName		NVARCHAR(100) 	 NULL, 
    BaseCost		NVARCHAR(100) 	 NULL, 
    ActType		NVARCHAR(100) 	 NULL, 
    Trade		NVARCHAR(100) 	 NULL, 
    TagetAdd		DECIMAL(19,5) 	 NULL, 
    OpenInterest		DECIMAL(19,5) 	 NULL, 
    InvestType		NVARCHAR(100) 	 NULL, 
    OldFundSeq		INT 	 NULL, 
    SetupDate		NCHAR(8) 	 NULL, 
    DurDate		NCHAR(8) 	 NULL, 
    AccDate		NCHAR(8) 	 NULL, 
    Interest		NVARCHAR(100) 	 NULL, 
    Barrier		NVARCHAR(100) 	 NULL, 
    EarlyRefund		NVARCHAR(100) 	 NULL, 
    TrustLevel		NVARCHAR(100) 	 NULL, 
    Remark1		NVARCHAR(100) 	 NULL, 
    Remark2		NVARCHAR(100) 	 NULL, 
    Remark3		NVARCHAR(100) 	 NULL, 
    FileSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TACFundMaster on KPX_TACFundMaster(CompanySeq,FundSeq) 
end 

if object_id('KPX_TACFundMasterLog') is null 
begin 
CREATE TABLE KPX_TACFundMasterLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    FundSeq		INT 	 NOT NULL, 
    FundName		NVARCHAR(100) 	 NOT NULL, 
    FundCode		NVARCHAR(100) 	 NOT NULL, 
    UMBond      INT NOT NULL, 
    BankSeq		INT 	 NOT NULL, 
    TitileName		NVARCHAR(100) 	 NULL, 
    FundKindM		INT 	 NOT NULL, 
    FundKindS		INT 	 NOT NULL, 
    ItemResult		NVARCHAR(100) 	 NULL, 
    BeforeRate		DECIMAL(19,5) 	 NULL, 
    FixRate		DECIMAL(19,5) 	 NULL, 
    Hudle		DECIMAL(19,5) 	 NULL, 
    Act		DECIMAL(19,5) 	 NULL, 
    SalesName		NVARCHAR(100) 	 NULL, 
    EmpName		NVARCHAR(100) 	 NULL, 
    ActCompany		NVARCHAR(100) 	 NULL, 
    BillCompany		NVARCHAR(100) 	 NULL, 
    SetupTypeName		NVARCHAR(100) 	 NULL, 
    BaseCost		NVARCHAR(100) 	 NULL, 
    ActType		NVARCHAR(100) 	 NULL, 
    Trade		NVARCHAR(100) 	 NULL, 
    TagetAdd		DECIMAL(19,5) 	 NULL, 
    OpenInterest		DECIMAL(19,5) 	 NULL, 
    InvestType		NVARCHAR(100) 	 NULL, 
    OldFundSeq		INT 	 NULL, 
    SetupDate		NCHAR(8) 	 NULL, 
    DurDate		NCHAR(8) 	 NULL, 
    AccDate		NCHAR(8) 	 NULL, 
    Interest		NVARCHAR(100) 	 NULL, 
    Barrier		NVARCHAR(100) 	 NULL, 
    EarlyRefund		NVARCHAR(100) 	 NULL, 
    TrustLevel		NVARCHAR(100) 	 NULL, 
    Remark1		NVARCHAR(100) 	 NULL, 
    Remark2		NVARCHAR(100) 	 NULL, 
    Remark3		NVARCHAR(100) 	 NULL, 
    FileSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 
