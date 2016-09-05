/**********************************************************/
/*Project:			Mapping with STATA					  */
/*Description: 										 	  */
/*					Code to create maps					  */
/*Created 			August  2016 						  */
/*Last Updated		August 24, 2016						  */
/*Log File			maps.log							  */
/*Programmed by:	Fadic								  */			
/*Input Files	
					raw_files\Limiti_2014_WGS84_g...\itdb_prov
					raw_files\Limiti_2014_WGS84_g...\itdb_reg
					raw_files\Limiti_2014_WGS84_g...\itdb_com
					2010_Province_Fabbisogni_caratteristiche_prestazioni_generali.csv
					Metadati_Enti.xlsx
															*/
/*Output files	
														  */
/**********************************************************/
		capture log close
		cd "your dir" /*Setting Diretory*/
		log using "maps.log", replace
		
		cap ssc install scmap   /*Install it if you dont have one*/
		cap ssc install shp2dta 

		/*Creates the STAT files from shapefiles- They are already created in the FOLDER*/
		cd "yout dir\\GIS"	
		shp2dta using prov2011_g.shp, database(itdb_prov) coordinates(itcoord_prov)  gencentroids(stub)  genid(center)
		shp2dta using com2011_g.shp, database(itdb_com) coordinates(itcoord_com)  gencentroids(stub)  genid(center)
		shp2dta using reg2011_g.shp, database(itdb_reg) coordinates(itcoord_reg)  gencentroids(stub)  genid(center)
		clear
		
cd "your dir" /*Setting Diretory Again*/
		
	/*Import and create the indicators*/
	local provindicators "delimited Data\2010_Province_Fabbisogni_caratteristiche_prestazioni_generali.csv, delimiter(";")"
	import `provindicators' 
	save "Data\indicators", replace	

	/*Import and create the province level information from OPennCivitas*/

	clear
	local enti "excel Data\Metadati_Enti.xlsx, sheet("Comuni_Province") firstrow"
	import `enti'
	keep PROVINCIA_ISTAT_COD PROVINCIA_SIGLA REGIONE_DENOMINAZIONE PROVINCIA_DES  	/*Keeping variables we need*/
	gen COD_PRO=real(PROVINCIA_ISTAT_COD )  /*Transform from String to Number*/
	collapse COD_PRO, by(PROVINCIA_ISTAT_COD PROVINCIA_SIGLA REGIONE_DENOMINAZIONE PROVINCIA_DES) /*The information is at city level, we use province level */
	save "data\prov_inf", replace
	
/*Load dataset*/
		use  "data\indicators", clear
		rename provincia_istat_cod COD_PRO   
		merge 1:1 COD_PRO using  "data\prov_inf"  /*Merge with Province info*/
		keep if _merge==3
		drop _merge
		merge 1:1 COD_PRO using  "GIS\itdb_prov"  /*Merge with Province info from GIS file*/
		
		rename COD_PRO province_code

/*Normalize the DATA*/
		su ind3, de
		local avg=r(mean)
		local sd=r(sd)
		gen indicator=(ind3-`avg')/`sd'
		
		
/*Now We map All Of Province Code */
	spmap indicator  using "GIS\itcoord_prov" , id(center) 
	graph export "Output\map_1.png", as(png) replace
	
/*Now We map All Of Province Code with Color */
	spmap indicator using "GIS\itcoord_prov" , id(center) ///
		fcolor(Blues) osize(none) 	 clmethod(quantile)     		
	graph export "Output\map_2.png", as(png) replace
		
/*Conditioning on some provinces */
	spmap indicator  using "GIS\itcoord_prov" if center==1 | center==2 | center==3, id(center) ///
	title ( "Index of Expenditure Vs. Needs") ///
			fcolor(Blues) osize(thick thick) 
			
			/*Osize is the outline of the map*/
			/*We can control how each set of labels and how thick is the outliner for each one*/
			
/*Adding Titles*/
	spmap indicator  using "GIS\itcoord_prov" , id(center) ///
	title ( "Index of Expenditure Vs. Needs") ///
			fcolor(Blues) osize(thick thick thick thick thick)   /*Osize is the outline of the map*/
			
	
/*Conditioning on some provinces-Changing Legend */
	spmap indicator  using "GIS\itcoord_prov" , id(center) ///
	title ( "Index of Expenditure Vs. Needs" ) subtitle("From Open Civitas") ///
			fcolor(Blues) osize( thin) ///  		/*Osize is the outline of the map*/
		clbreaks( -1 0 1 2 ) ///
		legend(label(2 "Less than -1") label(3 "Between -1 and 0" ) ///
		label(4 "Between 0 and 1"  ) label(5 "More than 1"  ) ) ///
		legtitle("Legend") 

/*Superimposing */	

 preserve 
 keep center NOME_PRO x_stub y_stub
 tempfile file 
 save  "data\basemap_part.dta", replace
 restore 


/*Map of communities- Adding the centroid */	


spmap indicator  using "GIS\itcoord_prov" , id(center) ///
		fcolor(Blues) osize( thin) ///  		/*Osize is the outline of the map*/
		point( xcoord( x_stub) ycoord( y_stub)   size( vsmall   ) )   
		graph export "Output\map_3A.png", as(png) replace 

	
spmap indicator  using "GIS\itcoord_prov" , id(center) ///
	title ( "Index of Expenditure Vs. Needs" ) subtitle("Open Civitas") ///
		fcolor(Blues) osize( thin) ///  		/*Osize is the outline of the map*/
		clbreaks( -1 0 1 2 )  ///
		legend(label(2 "Less than -1") label(3 "Between -1 and 0" ) ///
		label(4 "Between 0 and 1"  ) label(5 "More than 1"  ) ) ///
		legtitle("Legend") ///
		point( xcoord( x_stub) ycoord( y_stub)   size( vsmall   ) )   
	graph export "Output\map_3b.png", as(png) replace 
 
 
spmap indicator  using "GIS\itcoord_prov" , id(center) ///
	title ( "Index of Expenditure Vs. Needs" ) subtitle("From Open Civitas") ///
		fcolor(Blues) osize( thin) ///  		/*Osize is the outline of the map*/
		clbreaks( -1 0 1 2 )  ///
		legend(label(2 "Less than -1") label(3 "Between -1 and 0" ) ///
		label(4 "Between 0 and 1"  ) label(5 "More than 1"  ) ) ///
		legtitle("Legend")   ///
		point( xcoord( x_stub) ycoord( y_stub)   size( vsmall   ) )  /// 
		label(data("data\basemap_part.dta") xcoord( x_stub) ycoord(y_stub) ///
		label(NOME_PRO) size(*0.5 ..) position(0 6) length(26))
		graph export "Output\map_4.png", as(png) replace
/*Map of communities- SUPERIMPOSE Regional Map*/

preserve 
use "gis\itcoord_reg", clear
rename _ID center
merge m:1 center using "gis\itdb_reg"
rename  center _ID
save "data\basemap_reg.dta", replace 
restore 
		 
spmap indicator  using "GIS\itcoord_prov" , id(center) ///
	title ( "Index of Expenditure Vs. Needs" ) subtitle("From Open Civitas") ///
		fcolor(Blues) osize( thin) ///  		/*Osize is the outline of the map*/
		clbreaks( -1 0 1 2 )  ///
		legend(label(2 "Less than -1") label(3 "Between -1 and 0" ) ///
		label(4 "Between 0 and 1"  ) label(5 "More than 1"  ) ) ///
		legtitle("Legend")   ///
		polygon (data("data\basemap_reg.dta") ocolor(gs14) osize(thick))
	graph export "Output\map_5.png", as(png) replace

	

/*Map of communities- SUPERIMPOSE Regional Map, dissolve provincial borders*/

preserve 
use "gis\itcoord_reg", clear
rename _ID center
merge m:1 center using "gis\itdb_reg"
keep if center<10
rename  center _ID
save "data\basemap_reg_part.dta", replace 
restore 
		 
spmap indicator  using "GIS\itcoord_prov" , id(center) ///
	title ( "Index of Expenditure Vs. Needs" ) subtitle("From Open Civitas") ///
		fcolor(Blues) osize(thin) ocolor(none none none none) ///  		/*Osize is the outline of the map*/
		clbreaks( -1 0 1 2 )  ///
		legend(label(2 "Less than -1") label(3 "Between -1 and 0" ) ///
label(4 "Between 0 and 1"  ) label(5 "More than 1"  ) ) ///
		legtitle("Legend")   ///
		polygon (data("data\basemap_reg_part.dta") ocolor(black) osize(thick))
graph export "Output\map_6.png", as(png) replace
	
	
