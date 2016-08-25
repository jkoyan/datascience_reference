### Track Credit\Debit and Gift card settlement discrepancies :

#### Project Overview
Retail Stores or Quick Service Restaurants often use a store and forward (SAF) mechanism to authorize credit\debit\gift tranactions under a certain pre-defined limit in a scenario 
where the credit card system is not able to communicate with the credit card processor server. It could because of a network issue in the store or other factors that affect 
communications. The idea is to avoid longer wait times, improve Speed of Service. The credit card authorization request is encrypted and 
stored until communications is restored at wich point the authorizations are sent to the server to be approved. There are three posble outcomes
in this case :
	1. The authorized amount is  approved
	2. The authorized amount was approved for a lesser amount. For e.g. if the SAF limit was set to under $ 20.00, 
	   The customer placed an order for $ 15.00. Since it was a SAF order the amount was approved in the store, 
	   but the credit card processor authorizes only $ 12.00 because of insufficient funds in the bank. 
	   The store now has to write-off $ 3.00 on that order.
    3. The third outcome is that the authorization was not approved, in which case the store has lost $ 15.00  	   
	
Scenarios 2 and 3 are rare but it does occur. The other aspect to this situation is that it could take a day or more for communications to be restored, so a store could end up having numerous SAF
orders in the queue as a result the credit authorizations are authorized a few days later.  The credit\debit\gift card processor companies have a batch process that is executed on a nightly basis to settle all card transactions
for a business day an the money is credited to the Store's Bank account, the amount credited is refrred to as the Bank Settlement Amount. In an ideal condition Bank Settlement should equal to Sales  however it's obvious 
that the Sales Amount will not always tie with the Bank Settlemt Amount thereby causing discrepancies. This calls for a reporting feature which can be used to track the underlying cause of the discrepancy. 

We have a database called PosStoreDB which contains three tables  viz.

1. Detail.PosOrder - Order transactions rung in from the Point of Sale Solution (POS). It contains detaillsbout the specifics of the order, such as the Total Amount, Credit Card Amount, Gift Card and Debit Card Amount.
2. Detail.PosTransaction - The PosTransaction table contains details about the type of tender such as cash, credit, debit and gift. A unique Reference numberi associated with each tender record. 
3. Detail.CardSettlement - The table contains information if a credit\debit\gift authorizaton request was settled by the Bank (i.e money in the bank).

#### Development :

* Requirements:

1. Write a table-valued function to return the Order Number, Card Amount, Settlement Amount and a Comment indicating status if a card authorization was setted by the bank. The results should be for each credit authorization.
Keep in mind that a Order could have multiple tenders i.e. credit\debit\gift. 

2. Write a table-valued function to return the Order Number, Card Amount, Settlement Amount and a Comment indicating status if a card authorization was setted by the bank. The results should be summarized across 
all tenders for an order.

Table-Valued functions are helpful because the results can be filtered using where conditions just like a sql query,  these will be used as the data-source to feed different clients such as reports, 
mobile applications a web-server end-point.

* Implementation :

Two new table-value functions were created in the Database, the usage of the functions are as follows :
	1. Report.fnGetCardSettlementDetails:
		select * from Report.fnGetCardSettlementDetails('2016/07/06 12:00:00 AM','2016/07/06 12:59:59 PM')
	
	2. Report.fnGetCardSettlementSummary:
		select * from Report.fnGetCardSettlementSummary('2016/07/06 12:00:00 AM','2016/07/06 12:59:59 PM')
	
* Intructions for Database setup:
	1. Restore database - The PosStoreDb database was created on a Microsoft SQL Server 2012. The database backup is in the db directory.
	Restore the database on a SQL Server 2012 or up instance sql server instance.
	
	2. Scripts - 
		a. The Create database  script is in the \scripts\Create-PosStoreDB.sqlCreate-PosStoreDB.sql, it contains sql scripts to create the database and the database objects.
		b. The User-Defined-Functions.sql contains the scripts to create the functions mentioned in the Implementation section above.
  