USE [master]
GO
/****** Object:  Database [PosStoreDB]    Script Date: 8/25/2016 08:13:04 AM ******/
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'PosStoreDB')
BEGIN
CREATE DATABASE [PosStoreDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'PosStoreDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\PosStoreDB.mdf' , SIZE = 30720KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'PosStoreDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\PosStoreDB_log.ldf' , SIZE = 26816KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
END

GO
ALTER DATABASE [PosStoreDB] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [PosStoreDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [PosStoreDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [PosStoreDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [PosStoreDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [PosStoreDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [PosStoreDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [PosStoreDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [PosStoreDB] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [PosStoreDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [PosStoreDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [PosStoreDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [PosStoreDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [PosStoreDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [PosStoreDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [PosStoreDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [PosStoreDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [PosStoreDB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [PosStoreDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [PosStoreDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [PosStoreDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [PosStoreDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [PosStoreDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [PosStoreDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [PosStoreDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [PosStoreDB] SET RECOVERY FULL 
GO
ALTER DATABASE [PosStoreDB] SET  MULTI_USER 
GO
ALTER DATABASE [PosStoreDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [PosStoreDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [PosStoreDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [PosStoreDB] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'PosStoreDB', N'ON'
GO
USE [PosStoreDB]
GO
/****** Object:  Schema [Config]    Script Date: 8/25/2016 08:13:04 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Config')
EXEC sys.sp_executesql N'CREATE SCHEMA [Config]'

GO
/****** Object:  Schema [Detail]    Script Date: 8/25/2016 08:13:04 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Detail')
EXEC sys.sp_executesql N'CREATE SCHEMA [Detail]'

GO
/****** Object:  Schema [Report]    Script Date: 8/25/2016 08:13:04 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Report')
EXEC sys.sp_executesql N'CREATE SCHEMA [Report]'

GO
/****** Object:  Schema [Staging]    Script Date: 8/25/2016 08:13:04 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Staging')
EXEC sys.sp_executesql N'CREATE SCHEMA [Staging]'

GO
/****** Object:  UserDefinedFunction [Report].[fnGetCardSettlementDetails]    Script Date: 8/25/2016 08:13:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Report].[fnGetCardSettlementDetails]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'	-- ==============================================================================================================================================
			-- Author:		Jimmy Koyan
			-- Create date: 2016/06/09
			-- Description:	Queries the Detail.PosOrder, Detail.PosTransaction and the Detail.CardSettlement tables to return the Credit Card Transactions for the corresponding orders.
			--				The data can be used to determine card (Debit, Credit and Gift) settlement discrepancies.
			-- ===============================================================================================================================================
			CREATE FUNCTION [Report].[fnGetCardSettlementDetails]
			(	
				@BeginDate [datetime], @EndDate [datetime]
			)
			RETURNS @tblOutOrderCreditRecords TABLE 
					(
						Id INT IDENTITY,
						PosDate DATETIME,
						TerminalNumber INT,
						OrderNumber INT,
						PosCCAmt MONEY,
						CCTransAmt Money,
						BankSettlementAmt MONEY,
						SettlementDate DATETIME,
						ReferenceNumber INT,
						CardType VARCHAR(10) NULL,
						SettlementComment VARCHAR(100),
						SafTransaction BIT,
						SafApprovedAmount MONEY NULL,
						SafNumber VARCHAR(1000) NULL,
						SafStatus VARCHAR(50) NULL,
						SafProcessDate DATETIME NULL,
						SafComment VARCHAR(100)
					)
			AS
			BEGIN

			INSERT INTO @tblOutOrderCreditRecords ( PosDate, TerminalNumber, OrderNumber, PosCCAmt, CCTransAmt,
														BankSettlementAmt, SettlementDate, ReferenceNumber, CardType, 
														SettlementComment, SafTransaction, SafApprovedAmount, SafNumber, SafStatus, SafProcessDate, SafComment
														)
						SELECT	O.PosDate, O.TerminalNumber, ISNULL(O.OrderNumber,S.PeripheralNumber) OrderNumber, CASE WHEN S.Type=''Gift'' THEN O.GiftAmt
																										WHEN S.Type=''Credit'' THEN O.PosCCAmt
																										WHEN S.Type =''Debit'' THEN O.DebitAmt
																										ELSE O.PosCCAmt END PosCCAmt,S.CCTransAmt,
								S.BankSettlementAmt, S.SettlementDate, S.ReferenceNumber, S.cardType,
								S.SettlementComment, S.SafTransaction, S.SafApprovedAmount, S.SafNumber, SafStatus, S.SafProcessDate, S.SafComment		   	
							FROM
							( -- INNER JOIN ON POSOrder and FCTTransaction Tables
								SELECT	PO.OrderDate PosDate, PO.TerminalID TerminalNumber, PO.OrderNumber, CASE WHEN OrderType = 4 THEN CreditCardAmount*-1 ELSE CreditCardAmount END PosCCAmt
								, CASE WHEN OrderType = 4 THEN GiftCardRedemAmount*-1 ELSE GiftCardRedemAmount END GiftAmt, CASE WHEN OrderType = 4 THEN DebitCardAmount*-1 ELSE DebitCardAmount END DebitAmt
								FROM Detail.POSOrder PO 
								WHERE PO.OrderDate BETWEEN @BeginDate AND @EndDate AND ( ISNULL(PO.CreditCardAmount,0.00) > 0.00 OR ISNULL(PO.GiftCardRedemAmount,0.00) > 0.00 OR ISNULL(PO.DebitCardAmount,0.00) > 0.00)
							) O 
						FULL OUTER JOIN 
						( 
							-- FULL OUTER JOIN ON Detail.StarposTransaction and Detail.CardSettlement Tables
							SELECT  DS.PeripheralNumber,ISNULL(DS.AmountCollected,DC.TransactionAmount) CCTransAmt,
								DC.TransactionAmount BankSettlementAmt, DC.BusinessDate SettlementDate, CAST (ISNULL(DC.ReferenceNumber,DS.ReferenceNumber) AS INT) ReferenceNumber, ISNULL(DC.CardType,DS.CardType) cardType, 
								CASE WHEN DC.TransactionDate IS NULL THEN ''Not Yet Settled''
																		WHEN  DC.BusinessDate = DC.TransactionDate THEN ''Settled Same Day'' 
																		WHEN TransactionDate > DC.BusinessDate THEN ''Settled Next Day''	
																		WHEN TransactionDate < DC.BusinessDate THEN ''Settled Prior Day'' END SettlementComment,
								CASE WHEN DS.SafNumber IS NOT NULL THEN 1 ELSE 0 END SafTransaction, DS.SafApprovedAmount, DS.SafNumber, DS.SafStatus, DS.SafProcessDate,
								CASE WHEN SafNumber IS NOT NULL AND SafApprovedAmount = DS.AmountCollected THEN ''Saf Approved'' 
										WHEN SafNumber IS NOT NULL AND SafApprovedAmount = 0.00  THEN ''Saf Declined''
										WHEN SafNumber IS NOT NULL AND SafApprovedAmount < DS.AmountCollected  THEN ''Saf Partial Approval'' END SafComment,
										DS.Type 
							FROM Detail.PosTransaction DS
							FULL OUTER JOIN Detail.CardSettlement DC 
													ON  DC.ReferenceNumber = DS.ReferenceNumber AND
														ISNULL(DC.AuthCode,'''') = ISNULL(DS.AuthNumber,'''') AND
														ABS(DC.TransactionAmount) = ABS(DS.AmountCollected) 
														--AND DS.OrderCloseTime BETWEEN @BeginDate AND @EndDate 
							WHERE DS.Type not in(''Cash'') AND DS.OrderCloseTime BETWEEN @BeginDate AND @EndDate
						) S 
						ON O.OrderNumber = S.PeripheralNumber
			--- End of Code here

		
				RETURN
			END
' 
END

GO
/****** Object:  UserDefinedFunction [Report].[fnGetCardSettlementSummary]    Script Date: 8/25/2016 08:13:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Report].[c]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'	-- ==============================================================================================================================================
			-- Author:		Jimmy Koyan
			-- Create date: 2016/06/09
			-- Description:	Queries the Detail.PosOrder, Detail.PosTransaction and the Detail.CardSettlement tables to return the Credit Card Transactions for the corresponding orders.
			--				The data can be used to determine card (Debit, Credit and Gift) settlement discrepancies.
			-- ===============================================================================================================================================
			CREATE FUNCTION [Report].[fnGetCardSettlementSummary]
			(	
				@BeginDate [datetime], @EndDate [datetime]
			)
		RETURNS @tblOutOrderCreditSummaryRecords TABLE 
				(
					PosDate DATETIME,
					SettlementDate DATETIME,
					ReferenceNumber INT,
					TerminalNumber INT,
					OrderNumber INT,
					PosCCAmt MONEY,
					CCTransAmt Money,
					BankSettlementAmt MONEY,
					CCDiscrepancyAmt MONEY,
					PosOrderAmt MONEY,
					SettlementComment VARCHAR(100)
				)
		AS
		BEGIN

			INSERT INTO @tblOutOrderCreditSummaryRecords ( PosDate, SettlementDate, ReferenceNumber, TerminalNumber, OrderNumber, PosCCAmt, CCTransAmt,
														BankSettlementAmt, CCDiscrepancyAmt, PosOrderAmt, SettlementComment
														)
						SELECT	O.PosDate, MIN(S.SettlementDate) SettlementDate, MIN(S.ReferenceNumber) ReferenceNumber, 
								O.TerminalNumber, O.OrderNumber, MIN(O.PosCCAmt)+MIN(O.GiftAmt)+MIN(O.DebitAmt) PosCCAmt,SUM(S.CCTransAmt) CCTransAmt,
								SUM(S.BankSettlementAmt) BankSettlementAmt, 
								SUM(ISNULL(S.BankSettlementAmt,0.00)) - (MIN(O.PosCCAmt)+MIN(O.GiftAmt)+MIN(O.DebitAmt))   CCDiscrepancyAmt, 
								CASE WHEN MIN(OrderType) = 4 THEN (MIN(O.TotalFoodSale)+MIN(O.TaxCollected)-(MIN(O.CouponAmount)+MIN(O.PromoAmount)+MIN(O.FreeAmount)+MIN(O.CentsOffAmount))) * -1
									 ELSE  (MIN(O.TotalFoodSale)+MIN(O.TaxCollected)-(MIN(O.CouponAmount)+MIN(O.PromoAmount)+MIN(O.FreeAmount)+MIN(O.CentsOffAmount))) END PosOrderAmt, 
								MIN(S.SettlementComment) SettlementComment		   	
						 FROM
							( 
								SELECT	PO.OrderDate PosDate, PO.TerminalID TerminalNumber, PO.OrderNumber, CASE WHEN OrderType = 4 THEN CreditCardAmount*-1 ELSE CreditCardAmount END  PosCCAmt,
										PO.GiftCardRedemAmount GiftAmt, CASE WHEN OrderType = 4 THEN PO.DebitCardAmount*-1 ELSE PO.DebitCardAmount END  DebitAmt,
										ISNULL(TotalFoodSale,0.00) TotalFoodSale, ISNULL(TaxCollected,0.00) TaxCollected, ISNULL(CouponAmount,0.00) CouponAmount, 
										ISNULL(PromoAmount,0.00) PromoAmount, ISNULL(FreeAmount,0.00) FreeAmount, ISNULL(CentsOffAmount,0.00) CentsOffAmount,
										OrderType
								FROM Detail.POSOrder PO 
								WHERE PO.OrderDate BETWEEN @BeginDate AND @EndDate AND ( ISNULL(PO.CreditCardAmount,0.00) > 0.00 OR ISNULL(PO.GiftCardRedemAmount,0.00) > 0.00 OR ISNULL(PO.DebitCardAmount,0.00) > 0.00)
							) O 
						FULL OUTER JOIN 
						( 
							-- FULL OUTER JOIN ON Detail.PosTransaction and Detail.CardSettlement Tables
							SELECT  DS.PeripheralNumber,ISNULL(DS.AmountCollected,0.00) CCTransAmt,
								DC.TransactionAmount BankSettlementAmt, DC.BusinessDate SettlementDate, CAST (ISNULL(DC.ReferenceNumber,DS.ReferenceNumber) AS INT) ReferenceNumber, ISNULL(DC.CardType,DS.CardType) cardType, 
								CASE WHEN DC.TransactionDate IS NULL THEN ''Not Yet Settled''
																		WHEN  DC.BusinessDate = DC.TransactionDate THEN ''Settled Same Day'' 
																		WHEN TransactionDate > DC.BusinessDate THEN ''Settled Next Day''	
																		WHEN TransactionDate < DC.BusinessDate THEN ''Settled Prior Day'' END SettlementComment,
								CASE WHEN DS.SafNumber IS NOT NULL THEN 1 ELSE 0 END SafTransaction, DS.SafApprovedAmount, DS.SafNumber, DS.SafStatus, DS.SafProcessDate,
								CASE WHEN SafNumber IS NOT NULL AND SafApprovedAmount = DS.AmountCollected THEN ''Saf Approved'' 
									 WHEN SafNumber IS NOT NULL AND SafApprovedAmount = 0.00  THEN ''Saf Declined''
									 WHEN SafNumber IS NOT NULL AND SafApprovedAmount < DS.AmountCollected  THEN ''Saf Partial Approval'' END SafComment 
							FROM Detail.PosTransaction DS
							FULL OUTER JOIN Detail.CardSettlement DC 
													ON  DC.ReferenceNumber = DS.ReferenceNumber AND
														ISNULL(DC.AuthCode,'''') = ISNULL(DS.AuthNumber,'''') AND
														ABS(DC.TransactionAmount) = ABS(DS.AmountCollected)
							WHERE DS.Type not in(''Cash'') AND DS.OrderCloseTime BETWEEN @BeginDate AND @EndDate
						) S 
						ON O.OrderNumber = S.PeripheralNumber
						GROUP BY O.OrderNumber, O.PosDate, O.TerminalNumber
			--- End of Code here
			INSERT INTO @tblOutOrderCreditSummaryRecords ( PosDate, SettlementDate, ReferenceNumber, TerminalNumber, OrderNumber, PosCCAmt, CCTransAmt,
														BankSettlementAmt, CCDiscrepancyAmt, PosOrderAmt, SettlementComment
														)
						SELECT NULL,BusinessDate,ReferenceNumber,NULL,NULL,NULL,NULL,TransactionAmount,NULL,NULL,''Settled Same Day'' 
						FROM Detail.CardSettlement C 
						WHERE CONVERT(VARCHAR,C.BusinessDate,111) BETWEEN CONVERT(VARCHAR,@BeginDate,111) AND CONVERT(VARCHAR,@EndDate,111) 
							  AND AuthCode not in (SELECT distinct ISNULL(AuthNumber,'''') AuthNumber FROM Detail.PosTransaction WHERE OrderCloseTime BETWEEN @BeginDate AND @EndDate)
							  AND ReferenceNumber in (SELECT distinct ReferenceNumber FROM Detail.PosTransaction WHERE OrderCloseTime BETWEEN @BeginDate AND @EndDate)
		
				RETURN
			END
' 
END

GO
/****** Object:  Table [Detail].[CardSettlement]    Script Date: 8/25/2016 08:13:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Detail].[CardSettlement]') AND type in (N'U'))
BEGIN
CREATE TABLE [Detail].[CardSettlement](
	[Id] [int] NOT NULL,
	[TransactionCode] [varchar](10) NULL,
	[UserID] [varchar](10) NULL,
	[ReferenceNumber] [varchar](15) NOT NULL,
	[TransactionAmount] [money] NULL,
	[BusinessDate] [datetime] NOT NULL,
	[TransactionDate] [datetime] NULL,
	[TransactionTime] [time](7) NULL,
	[CardType] [varchar](10) NULL,
	[SettleStatus] [varchar](10) NULL,
	[AuthCode] [varchar](20) NULL,
 CONSTRAINT [PK_Detail.CardSettlement] PRIMARY KEY CLUSTERED 
(
	[Id] ASC,
	[BusinessDate] ASC,
	[ReferenceNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Detail].[POSOrder]    Script Date: 8/25/2016 08:13:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Detail].[POSOrder]') AND type in (N'U'))
BEGIN
CREATE TABLE [Detail].[POSOrder](
	[OrderID] [int] NOT NULL,
	[TerminalID] [tinyint] NOT NULL,
	[OrderNumber] [int] NOT NULL,
	[OrderDate] [datetime] NULL,
	[EmployeeID] [int] NOT NULL,
	[DestinationID] [tinyint] NOT NULL,
	[OrderType] [tinyint] NULL,
	[TotalNonFoodSale] [money] NULL,
	[TotalFoodSale] [money] NULL,
	[TotalTaxableSale] [money] NULL,
	[TaxCollected] [money] NULL,
	[PromoAmount] [money] NULL,
	[PromoCount] [tinyint] NULL,
	[CouponAmount] [money] NULL,
	[CouponCount] [tinyint] NULL,
	[FreeAmount] [money] NULL,
	[FreeCount] [tinyint] NULL,
	[FCTTranID] [int] NULL,
	[CentsOffAmount] [money] NULL,
	[CentsOffCount] [tinyint] NULL,
	[CreditCardAmount] [money] NULL,
	[GiftCardSaleAmount] [money] NULL,
	[GiftCardSaleCount] [smallint] NULL,
	[GiftCardRedemAmount] [money] NULL,
	[GiftCardRedemCount] [smallint] NULL,
	[DebitCardAmount] [money] NULL,
	[CashBackAmount] [money] NULL,
	[OrderSource] [tinyint] NOT NULL CONSTRAINT [DF__POSOrder__OrderS__1273C1CD]  DEFAULT ((1)),
 CONSTRAINT [Detail.tblPOSOrder_PK] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Detail].[PosTransaction]    Script Date: 8/25/2016 08:13:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Detail].[PosTransaction]') AND type in (N'U'))
BEGIN
CREATE TABLE [Detail].[PosTransaction](
	[Id] [uniqueidentifier] NOT NULL,
	[TerminalId] [int] NOT NULL,
	[OrderNumber] [int] NOT NULL,
	[PeripheralNumber] [int] NOT NULL,
	[ReferenceNumber] [int] NULL,
	[AuthNumber] [varchar](20) NULL,
	[Type] [varchar](20) NULL,
	[CardType] [varchar](20) NULL,
	[CardNumber] [int] NULL,
	[AmountCollected] [money] NULL,
	[Troutd] [int] NULL,
	[Ctroutd] [int] NULL,
	[TenderTime] [datetime] NULL,
	[OrderCloseTime] [datetime] NULL,
	[CreateDate] [datetime] NOT NULL CONSTRAINT [DF_StarposTransaction_CreateDate]  DEFAULT (getdate()),
	[SafNumber] [varchar](1000) NULL,
	[SafStatus] [varchar](50) NULL,
	[SafApprovedAmount] [money] NULL,
	[SafProcessDate] [datetime] NULL,
 CONSTRAINT [PK_StarposTransaction] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
USE [master]
GO
ALTER DATABASE [PosStoreDB] SET  READ_WRITE 
GO
