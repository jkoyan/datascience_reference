USE PosStoreDB

DECLARE @BeginDate AS DATETIME
DECLARE @EndDate AS DATETIME

SELECT @BeginDate = '2016/07/05 12:00:00 AM', @EndDate = '2016/07/05 11:59:59 PM' 

SELECT	O.PosDate, O.TerminalNumber, ISNULL(O.OrderNumber,S.PeripheralNumber) OrderNumber, CASE WHEN S.Type='Gift' THEN O.GiftAmt
																										WHEN S.Type='Credit' THEN O.PosCCAmt
																										WHEN S.Type ='Debit' THEN O.DebitAmt
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
								CASE WHEN DC.TransactionDate IS NULL THEN 'Not Yet Settled'
																		WHEN  DC.BusinessDate = DC.TransactionDate THEN 'Settled Same Day' 
																		WHEN TransactionDate > DC.BusinessDate THEN 'Settled Next Day'	
																		WHEN TransactionDate < DC.BusinessDate THEN 'Settled Prior Day' END SettlementComment,
								CASE WHEN DS.SafNumber IS NOT NULL THEN 1 ELSE 0 END SafTransaction, DS.SafApprovedAmount, DS.SafNumber, DS.SafStatus, DS.SafProcessDate,
								CASE WHEN SafNumber IS NOT NULL AND SafApprovedAmount = DS.AmountCollected THEN 'Saf Approved' 
										WHEN SafNumber IS NOT NULL AND SafApprovedAmount = 0.00  THEN 'Saf Declined'
										WHEN SafNumber IS NOT NULL AND SafApprovedAmount < DS.AmountCollected  THEN 'Saf Partial Approval' END SafComment,
										DS.Type 
							FROM Detail.PosTransaction DS
							FULL OUTER JOIN Detail.CardSettlement DC 
													ON  DC.ReferenceNumber = DS.ReferenceNumber AND
														ISNULL(DC.AuthCode,'') = ISNULL(DS.AuthNumber,'') AND
														ABS(DC.TransactionAmount) = ABS(DS.AmountCollected) 
														--AND DS.OrderCloseTime BETWEEN @BeginDate AND @EndDate 
							WHERE DS.Type not in('Cash') AND DS.OrderCloseTime BETWEEN @BeginDate AND @EndDate
						) S 
						ON O.OrderNumber = S.PeripheralNumber

