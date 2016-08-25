USE [PosStoreDB]
GO
/****** Object:  UserDefinedFunction [Report].[fnGetCardSettlementDetails]    Script Date: 8/25/2016 12:07:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Report].[fnGetCardSettlementDetails]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'	-- ==============================================================================================================================================
			-- Author:		Jimmy Koyan
			-- Create date: 2016/06/09
			-- Description:	Queries the Detail.PosOrder, Detail.StarPosTransaction and the Detail.CardSettlement tables to return the Credit Card Transactions for the corresponding orders.
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
/****** Object:  UserDefinedFunction [Report].[fnGetCardSettlementSummary]    Script Date: 8/25/2016 12:07:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Report].[fnGetCardSettlementSummary]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'	-- ==============================================================================================================================================
			-- Author:		Jimmy Koyan
			-- Create date: 2016/06/09
			-- Description:	Queries the Detail.PosOrder, Detail.StarPosTransaction and the Detail.CardSettlement tables to return the Credit Card Transactions for the corresponding orders.
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
