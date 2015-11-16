//ESS_LOCALE English_UnitedStates.Latin1@Binary
/*

Notes: Dollar Amount is allocated from a single Cost Center (associated with single method) to multiple cost centers.Method(defined in Version dimension defines the relation between source and target cost centers.
Facilities Allocation needs to done first since all other allocations are dependent on it.
All new methods in the Version dimension should be added in format : HMB_FR_<GL OUT account>_TO_<GL IN account>_<method description>.

Step 1: Clear Data from Alloc Source Amount, IN and OUT GL accounts.

Step 2: For HMB_FR_121886 TO_121786 SQFT_Site_NASt, 
			IF Alloc_Method Flag = YES Then Allocation Source Amount = Total Net Expenses;
			Total Net Expenses = 
			AC_BT1000 - Total Expense Accounts-Working 
			- AC_BT_BT0016 - Total Assessments-Working
			+ "AC_121786 - Assess-In-Maint Grnds Outside Fac + Blg"->Working

Step 3: Aggregate Cost Centers for Allocation Source Amount.;
			AC_121786 = Total Cost Centers-> Allocation Source Amount * Allocation%;
			AC_121886 = Allocation Source Amount * -1;

Step 7: For IN/OUT GL accounts for version : HMB_FR_121886 TO_121786 SQFT_Site_NASt , Working = Total Allocation Methods;

Step 6: Aggregate "HMB_FR_121886 TO_121786 SQFT_Site_NASt" Version Rollup by Cost Center and IN/OUT GL accounts.

Step 4: For all other allocation methods,
			IF Alloc_Method Flag = YES Then Allocation Source Amount = Total Net Expenses;
			Total Net Expenses =
			AC_BT1000 - Total Expense Accounts-Working  
			- AC_BT_BT0016 - Total Assessments-Working
			+ "AC_121786 - Assess-In-Maint Grnds Outside Fac + Blg"->Working

Step 5: Aggregate Cost Centers for Allocation Source Amount.;
			AC_<IN account> = Total Cost Centers Allocation Source Amount * Allocation%;
			AC_<OUT account> = Allocation Source Amount * -1;

Step 6: Aggregate Allocation Version Rollup by Cost Center and IN/OUT GL accounts.

Step 7: For IN/OUT GL accounts, Working = Total Allocation Methods;

*/

SET AGGMISSG ON;
SET CACHE HIGH;
SET UPDATECALC OFF;
SET CALCPARALLEL 2;
SET FRMLBOTTOMUP ON;


/************************BEGIN : Clear all IN/OUT accounts for all methods Version********************************************************/

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),@MATCH("Version","HMB*"))

	FIX(&WFP_Year1,&WFP_FcstMth:Dec)
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))) = #Missing;
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23))) = #Missing;
	"Allocation Source Amount"= #Missing;
	"Alloc_%" = #Missing;
	)
	ENDFIX

	FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))) = #Missing;
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23))) = #Missing;
	"Allocation Source Amount"= #Missing;
	"Alloc_%" = #Missing;
	)
	ENDFIX
ENDFIX

/************************BEGIN : Calculate the receiving Cost center Allocation Percent********************************************************/

FIX(&ANA_ExpWorking,&WFP_Year1,&WFP_Year2,&WFP_Year3,"Allocation Driver","Jan":"Dec","HMB_FR_121886_TO_121786 SQFT_Site_NASt")
AGG("Org");
ENDFIX

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),"HMB_FR_121886_TO_121786 SQFT_Site_NASt")

		FIX(&WFP_Year1,&WFP_FcstMth:Dec)
		"Alloc_%"(
		IF("Allocation Driver" <> #missing OR "Allocation Driver" <> 0 )
		"Alloc_%"= "Allocation Driver"/"Allocation Driver"->"Cost Center Total";
		ENDIF
		)
		ENDFIX

		FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
		"Alloc_%"(
		IF("Allocation Driver" <> #missing OR "Allocation Driver" <> 0 )
		"Alloc_%"= "Allocation Driver"/"Allocation Driver"->"Cost Center Total";
		ENDIF
		)
		ENDFIX
ENDFIX

/************************BEGIN : Assign Allocation Source Amount********************************************************/

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),"HMB_FR_121886_TO_121786 SQFT_Site_NASt")
		FIX(&WFP_Year1,&WFP_FcstMth:Dec)
		"Allocation Source Amount"(
		IF ("Alloc_Method"->"BegBal" == 1)
		"Allocation Source Amount"  = 	"AC_BT1000 - Total Expense Accounts"->"Working" 
										- "AC_BT_BT0016 - Total Assessments"->"Working"
										+ "AC_121786 - Assess-In-Maint Grnds Outside Fac + Blg"->"Working";
		ENDIF
		)
		ENDFIX

		FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
		"Allocation Source Amount"(
		IF ("Alloc_Method"->"BegBal" == 1)
		"Allocation Source Amount"  = 	"AC_BT1000 - Total Expense Accounts"->"Working" 
										- "AC_BT_BT0016 - Total Assessments"->"Working"
										+ "AC_121786 - Assess-In-Maint Grnds Outside Fac + Blg"->"Working";
		ENDIF
		)
		ENDFIX
ENDFIX


/********************************* BEGIN : Aggregate The Facilities methods for "HMB_FR_121886_TO_121786 SQFT_Site_NASt" Version*********************************/

FIX(&ANA_ExpWorking,&WFP_Year1,&WFP_Year2,&WFP_Year3,"Allocation Source Amount","HMB_FR_121886_TO_121786 SQFT_Site_NASt","Jan":"Dec") 
AGG("Org"); 
ENDFIX

/*********************************BEGIN: ALLOCATION CALC*********************************/

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),"HMB_FR_121886_TO_121786 SQFT_Site_NASt")

	FIX(&WFP_Year1,&WFP_FcstMth:Dec)
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))= "Allocation Source Amount"->"Cost Center Total"*"Alloc_%";
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))) = "Allocation Source Amount"*(-1);
	)
	ENDFIX

	FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))= "Allocation Source Amount"->"Cost Center Total"*"Alloc_%";
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))) = "Allocation Source Amount"*(-1);
	)
	ENDFIX
ENDFIX

/*Below Copies the data from HMB versions to Working*/

FIX(&ANA_ExpWorking, @RELATIVE(&WFP_ANACostCenters,0),"HMB_FR_121886_TO_121786 SQFT_Site_NASt")

	FIX(&WFP_Year1,&WFP_FcstMth:Dec)
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23))),@CHILDREN("Allocation_Methods"));
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))),@CHILDREN("Allocation_Methods"));
	)
	ENDFIX

	FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23))),@CHILDREN("Allocation_Methods"));
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))),@CHILDREN("Allocation_Methods"));
	)
	ENDFIX
ENDFIX


/********************************* BEGIN : Aggregate The Facilities methods for "HMB_FR_121886_TO_121786 SQFT_Site_NASt"(Facility) Version*********************************/

FIX(&ANA_ExpWorking,&WFP_Year1,&WFP_Year2,&WFP_Year3,"Jan":"Dec","HMB_FR_121886_TO_121786 SQFT_Site_NASt","Working")
AGG("Org");
ENDFIX



/******************************************************************************************************************
CALCULATE ALL (HMB*)VERSION EXCEPT "HMB_FR_121886_TO_121786 SQFT_Site_NASt"
******************************************************************************************************************
******************************************************************************************************************/


/************************BEGIN : Calculate the receiving Cost center Allocation Percent except "HMB_FR_121886_TO_121786 SQFT_Site_NASt"********************************************************/

FIX(&ANA_ExpWorking,&WFP_Year1,&WFP_Year2,&WFP_Year3,"Allocation Driver","Jan":"Dec",@REMOVE(@MATCH("Version","HMB*"),"HMB_FR_121886_TO_121786 SQFT_Site_NASt"))
AGG("Org");
ENDFIX

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),@REMOVE(@MATCH("Version","HMB*"),"HMB_FR_121886_TO_121786 SQFT_Site_NASt"))

		FIX(&WFP_Year1,&WFP_FcstMth:Dec)
		"Alloc_%"(
		IF("Allocation Driver" <> #missing OR "Allocation Driver" <> 0 )
		"Alloc_%"= "Allocation Driver"/"Allocation Driver"->"Cost Center Total";
		ENDIF
		)
		ENDFIX

		FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
		"Alloc_%"(
		IF("Allocation Driver" <> #missing OR "Allocation Driver" <> 0 )
		"Alloc_%"= "Allocation Driver"/"Allocation Driver"->"Cost Center Total";
		ENDIF
		)
		ENDFIX
ENDFIX

/************************BEGIN : Assign allocation source amountt"********************************************************/

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),@REMOVE(@MATCH("Version","HMB*"),"HMB_FR_121886_TO_121786 SQFT_Site_NASt"))

		FIX(&WFP_Year1,&WFP_FcstMth:Dec)
		"Allocation Source Amount"(
		IF ("Alloc_Method"->"BegBal" == 1)
		"Allocation Source Amount"  = 	"AC_BT1000 - Total Expense Accounts"->"Working" 
										- "AC_BT_BT0016 - Total Assessments"->"Working"
										+ "AC_121786 - Assess-In-Maint Grnds Outside Fac + Blg"->"Working";
		ENDIF
		)
ENDFIX

		FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
		"Allocation Source Amount"(
		IF ("Alloc_Method"->"BegBal" == 1)
		"Allocation Source Amount"  = 	"AC_BT1000 - Total Expense Accounts"->"Working" 
										- "AC_BT_BT0016 - Total Assessments"->"Working"
										+ "AC_121786 - Assess-In-Maint Grnds Outside Fac + Blg"->"Working";
		ENDIF
		)
		ENDFIX
ENDFIX


/********************************* BEGIN : Aggregate The Facilities methods for all except "HMB_FR_121886_TO_121786 SQFT_Site_NASt" version*********************************/

FIX(&ANA_ExpWorking,&WFP_Year1,&WFP_Year2,&WFP_Year3,"Allocation Source Amount",@REMOVE(@MATCH("Version","HMB*"),"HMB_FR_121886_TO_121786 SQFT_Site_NASt"),"Jan":"Dec") 
AGG("Org"); 
ENDFIX

/*********************************BEGIN: Allocation for all except "HMB_FR_121886_TO_121786 SQFT_Site_NASt" version*********************************/

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),@REMOVE(@MATCH("Version","HMB*"),"HMB_FR_121886_TO_121786 SQFT_Site_NASt"))

	FIX(&WFP_Year1,&WFP_FcstMth:Dec)
	"AC_121762"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))= "Allocation Source Amount"->"Cost Center Total"*"Alloc_%";
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))) = "Allocation Source Amount"*(-1);
	)
	ENDFIX

	FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))= "Allocation Source Amount"->"Cost Center Total"*"Alloc_%";
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))) = "Allocation Source Amount"*(-1);
	)
	ENDFIX
ENDFIX


/*Below Copies the data from HMB versions to Working*/

FIX(&ANA_ExpWorking,@RELATIVE(&WFP_ANACostCenters,0),@REMOVE(@MATCH("Version","HMB*"),"HMB_FR_121886_TO_121786 SQFT_Site_NASt"))

	FIX(&WFP_Year1,&WFP_FcstMth:Dec)
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23))),@CHILDREN("Allocation_Methods"));
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))),@CHILDREN("Allocation_Methods"));
	)
ENDFIX

	FIX(&WFP_Year2,&WFP_Year3,"Jan":"Dec")
	"AC_121786"(
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),17,23))),@CHILDREN("Allocation_Methods"));
	@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13)))->"Working" = 
@SUMRANGE(@MEMBER(@CONCATENATE("AC_",@SUBSTRING(@NAME(@CURRMBR("Version")),7,13))),@CHILDREN("Allocation_Methods"));
)
	ENDFIX
ENDFIX


/********************************* BEGIN : Aggregate The Facilities methods for all except "HMB_FR_121886_TO_121786 SQFT_Site_NASt" version*********************************/
FIX(&ANA_ExpWorking,&WFP_Year1,&WFP_Year2,&WFP_Year3,"Jan":"Dec",@REMOVE(@MATCH("Version","HMB*"),"HMB_FR_121886_TO_121786 SQFT_Site_NASt"),"Working")
AGG("Org");
ENDFIX
