# dirtyduck

### Download Data
curl https://data.cityofchicago.org/api/views/4ijn-s7e5/rows.csv?accessType=DOWNLOAD > inspections.csv

### Create postgres table
CREATE TABLE inspections (
	Inspection_ID VARCHAR(20)  NOT NULL,
	DBA_Name VARCHAR(100),
	AKA_Name VARCHAR(100),
	License_Num DECIMAL,
	Facility_Type VARCHAR(100),
	Risk VARCHAR(15),
	Address VARCHAR(100),
	City VARCHAR(100),
	State VARCHAR(2),
	Zip VARCHAR(10),
	Inspection_Date DATE,
	Inspection_Type VARCHAR(100),
	Results VARCHAR(100),
	Violations VARCHAR(50000),
	Latitude DECIMAL,
	Longitude DECIMAL,
	Location VARCHAR(40)
);

