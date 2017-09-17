************************** BEGINNING OF PROGRAM **************************;

/* Following commands are to create a combined dataset from consolidated files (2002-2013)
/* Some variables have the same name --
/* Some have year indicator in the variable names (i.e. OBTOTV12--variable from year 2012 )

/* Procedure involved
	1. Create macro lists of needed variables.
	2. Create a macro function that will chhage varaible names that contains year indicator to not having year indicator.
	3. Once all variables in each year have the same names, combine them all

***************************************************************************;



*);*/;/*'*/ /*"*/; %MEND; run;
OPTIONS NOCENTER DATE MPRINT MLOGIC SYMBOLGEN OBS=MAX;

/*MACRO LIST OF VARIABLES NEEDED FOR THE ANALYSIS */
%LET ID= DUPERSID;
%LET WT =  VARSTR VARPSU;
%LET DEMO=  SEX HISPANX;
%LET ACCESS=HAVEUS42 MDDLAY42 PMDLAY42 ADILWW42 ADRTWW42 ADILWW42;
%LET ATTD= ADINSA42 ADINSB42 ADRISK42 ADOVER42;
%LET DIFCT= GOTOUS42 TMTKUS42 DFTOUS42 DNDLAY42 MDUNAB42 DNUNRS42 PMUNRS42;
%LET HLTST= RTHLTH31 RTHLTH42 RTHLTH53 MNHLTH31 MNHLTH42 MNHLTH53;
%LET CAHPS= ADLIST42 ADEXPL42 ADRESP42 ADPRTM42;
%LET HABIT= ADSMOK42;
%LET ABSNT= DDNWRK31 DDNWRK42 DDNWRK53 DDNSCL31 DDNSCL31 DDNSCL42 DDNSCL53;
%LET OUTCME = PCS42 MCS42 ADHECR42 K6SUM42 PHQ242 ASMRCN53 ACTLIM53;
%LET ASTH_OTCM = ASSTIL53 ASSTIL31 ASTHDX ASATAK53 ;
%LET EMPST = EMPST31 EMPST42 EMPST53;
%LET DATE = BEGRFM31 BEGRFM42 BEGRFM53 BEGRFD31 BEGRFD42 BEGRFD53 BEGRFY31 BEGRFY42 BEGRFY53 ENDRFM31 ENDRFM42 ENDRFM53 ENDRFD31 ENDRFD42 ENDRFD53 ENDRFY31 ENDRFY42 ENDRFY53;
%LET YRLYVAR= %NRSTR(AGE|RACE|MSA|REGION|MARRY|SAQWT|TTLP|POVCAT|INSCOV|ASTHDX|UNINS|OBVSLF|OBTOTV|OBVEXP|OPTOTV|OPFEXP|OPDEXP|ERTOT|ERTEXP|ERTSLF|IPDIS|IPNGTD|IPTEXP|IPTSLF|IPNGTD|RXTOT|RXEXP|RXSLF|TOTEXP|TOTSLF|PERWT|DDBDYS|FTSTU|IPZERO|ERTEXP|EDUCYEAR|HIDEG|EDUCYR|EDRECODE|EDUYRDEG|PHY);

/*MACRO FUNCTION TO RENAME VARIABLE IN THE DATASET */
%MACRO RENAME(OLDVAR, NEWVAR);
	%LET k=1;
	%LET OLD=%SCAN(&OLDVAR, &K);
	%LET NEW=%SCAN(&NEWVAR, &K);
		%DO %WHILE(("&OLD" NE "")&("&NEW" NE ""));
			RENAME &OLD=&NEW;
			%LET K=%EVAL(&K+1);
			%LET old=%scan(&OLDVAR, &K);
			%LET new=%SCAN(&NEWVAR, &K);
		%END;
%MEND;

/*MACRO FUNCTION TO CREATE LIST OF OLD VARIABLE NAMES AND NEW DESIRED NAME (VAR NAME WITHOUT YEAR INDICATOR) */
%MACRO LIBDATA;
	/* Create libname*/
	LIBNAME SASDATA'E:\ShadaK\MEPS\SASDATA';
	LIBNAME CLN 'E:\ShadaK\MEPS\SASDATA\CleanedData';
	/*Get contents for data set (from the library), save result in an output data set */
	PROC CONTENTS DATA=SASDATA._ALL_ MEMTYPE=DATA
				  OUT=OUT NOPRINT;
	RUN;
	/*Sort before selecting unique dataset names*/
	PROC SORT DATA=OUT;
		BY MEMNAME NAME;
		RUN;
	/*Select desired unique data set names */
	DATA A ;
		SET OUT;
		BY MEMNAME NAME;
		/* Remove Medical Condition datasets--Their names're started with MC20XX */
		/* =: is the colon moodifier which means "to begin with" --similar to a wild card*/
		IF MEMNAME =: 'MC' THEN DELETE;
		/*remove duplicate of  produced from output data set */
		IF FIRST.MEMNAME;
		RUN;
	/*Create data set names as macro variables and get total number of data sets */
	DATA B;
	   SET A END=LAST;
	    BY MEMNAME NAME;
	     /*Create Macro variables with the value of the memnames */
	     CALL SYMPUT('DS'||LEFT(_N_), TRIM(MEMNAME)) ;
	     /*Create a macro variable for the total # of the datasets */
	     IF LAST THEN CALL SYMPUT ('TOTAL', LEFT(_N_));
	     RUN;
  /* Do loop to run through each dataset of consolidated data*/
  %DO i=1 %TO &TOTAL;
    /* Create variable name list that contain yearly indicator which need to rename before maerging the dataset*/
	  PROC SQL NOPRINT;
      		SELECT  NAME INTO: OLDLIST SEPARATED BY ' '
      		FROM DICTIONARY.COLUMNS
      		WHERE LIBNAME= 'SASDATA' & MEMNAME = %UNQUOTE(%STR(%'&&DS&i%')) & PRXMATCH ("/&YRLYVAR/", NAME);
      		QUIT;
      /* Create a macro for year indication---ds1=year 2002==VAR02 */
      /* This macro var will be used to indicate what number is need to extract from the selected var */
      %LET YR=%SYSFUNC(PUTN(%eval (01+&i), Z2.));
      /* Rename the selected variable by removing the numeric year indicator*/
      PROC SQL NOPRINT ;
      	 	SELECT PRXCHANGE("s/&YR//",-1, NAME) INTO: NEWLIST SEPARATED BY ' '
      	  	FROM DICTIONARY.COLUMNS
  	 		WHERE LIBNAME= 'SASDATA' & MEMNAME =%UNQUOTE(%STR(%'&&DS&i%')) & PRXMATCH ("/&YRLYVAR/", NAME);
      	 	QUIT;

		/* Create a dataset contains only variables needed to rename before making the rename process*/
    	DATA RN&&DS&i;
			SET SASDATA.&&DS&i (KEEP=&OLDLIST);
			%RENAME (&OLDLIST,&NEWLIST);
			RUN;

    	DATA PMN&&DS&i;
			SET SASDATA.&&DS&i (KEEP=&ID &DEMO &WT &ACCESS &ATTD &DIFCT &HLTST &CAHPS &OUTCME );
			RUN;

		DATA PMN1&&DS&i;
			SET SASDATA.&&DS&i (KEEP=&ID  &HABIT &DATE &ABSNT &EMPST &ASTH_OTCM );
			RUN;

		DATA COMBO&&DS&i;
			MERGE RN&&DS&i PMN&&DS&i PMN1&&DS&i;
			RUN;

	%END;

%MEND LIBDATA;


%LIBDATA;

/*COMBINE ALL NEWLY CREATED DATASETS WITH VARIBALE NAMES THAT CAN EASILY BE APPEND WITHOUT THE NEED TO RENAME VARIABLE WITH YEAR INDICATOR */
DATA CLN.CSL_2002_2013;
 SET COMBOCSL2002-COMBOCSL2013 INDSNAME = DSNAMES;
 	YEAR=PRXCHANGE('s/WORK.COMBOCSL//', -1, DSNAMES);
 	YEAR=COMPRESS (YEAR);
	 RUN;


/*CHECK IF ALL YEARS OF THE DATA IS INCLUDED */
PROC SQL;
SELECT YEAR AS YEAR, AVG(AGEX) AS MEAN_AGE, AVG(HAVEUS42)AS AVG_HAVEUS42, COUNT(ERTOT) AS ER_TOTAL, MAX(OPTOTV) AS MAX_OPT_TOTAL
FROM  CLN.CSL_2002_2013
GROUP BY YEAR
;
QUIT;

PROC SQL;
SELECT YEAR AS YEAR, AVG(AGEX) AS MEAN_AGE, COUNT(DUPERSID) AS DUPERSID, MAX(PHQ242) AS PHQ2,
	min(K6SUM42) AS K6SUM42, MAX(ASMRCN53) AS ASMRCN53, MAX(PCS42) AS PCS, MAX(ACTLIM53) AS ACTLIM53, AVG(VARPSU) AS VARPS
FROM  CLN.CSL_2002_2013
GROUP BY YEAR
;
QUIT;
