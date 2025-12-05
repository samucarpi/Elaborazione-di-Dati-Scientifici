echo on
% EVRIDBDEMO Demo of the EVRIDB object
 
echo off
% Copyright © Eigenvector Research, Inc. 2024 Licensee shall not
%  re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The EVRIDB object is a wrapper for connecting to and managing a database.
% PLS_Toolbox include Apache Derby, an open source relational database
% implemented in Java. This demo will show how to create a simple database
% with Derby. Other connections are possible, see documentation for more
% info. 

pause
%-------------------------------------------------
% The following code creates an "in memory" database. These are used for
% temporary databases and are destroyed on command or when the JVM is shut
% down. This will show the basic usage of a database.
 
% Make sure java is set up..
evrijavasetup

% Create 'evridb' object.
mydb = evridb('type','derby_mem','dbname','evri_test_db')

%Simple table create
creat_query = [ 'CREATE TABLE evri_test_db.testTable '...
'('...
'myID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),' ...  
'name VARCHAR(100) NOT NULL,'...
'date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,'...
'notes VARCHAR(2000),'...
'CONSTRAINT TESTTABLE_PK PRIMARY KEY (myID)'...
')']; 
mydb.runquery(creat_query)

%Do simple insert
simple_insert = 'INSERT INTO evri_test_db.testTable (name) VALUES (''a'')';
mydb.runquery(simple_insert);

%Select results
simple_select = 'SELECT * FROM evri_test_db.testTable';
table_values = mydb.runquery(simple_select)

%Simple prepared statement, this is a way to add multiple recods quickly
%using MATLAB cell arrays.
mynames = {'b' 'c' 'd'}';
prepared_query = ['INSERT INTO evri_test_db.testTable (name) VALUES (?)'];
val = jpreparedstatement(mydb,prepared_query,mynames,{'String'});
table_values = mydb.runquery(simple_select)

%Bigger insert
newvals = {'e' 'dddddddd dddddddd gdffefe';...
  'f' 'sdfaswerfwet ewfq wtweqt weddddddd gdffefe';...
  'g' 'sdfasdfdsfe'};
prepared_query2 = ['INSERT INTO evri_test_db.testTable (name,notes) VALUES (?,?)'];
val = jpreparedstatement(mydb,prepared_query2,newvals,{'String' 'String'});
table_values = mydb.runquery(simple_select)
 
pause
%-------------------------------------------------
% Now clean up database. This is unnecessary but will be shown.

%Close and clear the database.
mydb.shutdown_derby_mem
clear('mydb')
 
pause
%-------------------------------------------------
% The following code creates a database on disk. This is a more traditional
% type of database and will keep data persistent. 

%Create folder for database files.
current_folder = pwd;
thisfolder = fullfile(tempdir,'evritestdb')
mkdir(thisfolder)
cd(thisfolder)
 
dbobj = evridb('type','derby');
dbobj.location = thisfolder; %getcachefolder;%TODO: Find best way to save this.
dbobj.dbname = 'evri_test_db';
dbobj.use_encryption = 'yes';
dbobj.encryption_hash = 'testdbhash123';
dbobj.create = 'yes';
dbobj.keep_persistent = 'yes';
dbobj.null_as_nan = 0;%Speeds up parsing.
 
dbobj.runquery(creat_query)
dbobj.runquery(simple_insert);
val = jpreparedstatement(dbobj,prepared_query,mynames,{'String'});
val = jpreparedstatement(dbobj,prepared_query2,newvals,{'String' 'String'});
table_values = dbobj.runquery(simple_select)
 
pause
%-------------------------------------------------
% Now clean up files.
 
%Close and clear the database.
dbobj.shutdown_derby
cd(current_folder)
rmdir(thisfolder,"s")
 
%End of EVRIDBDEMO
 
echo off