function [SQLite_Database] = connectSQLite()
    %connectSQLite connects to an SQLite Database and returns a database connection
    
    %Check that the sqlite-jbdc driver is on the Java search path
    jpath = javaclasspath('-all'); 
    match = strfind(jpath,'sqlite-jdbc');
    
    %If it's not -> Add it
    if isempty([match{:}])
        %Get the path to the sqlite-jbdc driver from the config settings
        jbdc_path = getConfigSetting('sqlite-jdbc','jbdc_path');

        %Add it to the dynamic path
        javaaddpath(jbdc_path);

        %Add it to the static path for next time
        JavaStaticPath = fullfile(prefdir,'javaclasspath.txt');
        fid = fopen(JavaStaticPath,'a');
        fprintf(fid,'%s\n',jbdc_path);
        fclose(fid);
    end 
    
    %Settings for SQLite Connection
    dbpath = getConfigSetting('Datastore','master_directory_path');
    user = ''; password = '';   %No file security -> So not accounts
    driver = 'org.sqlite.JDBC'; %Driver used for Access
    
    %Create URL for databse
    protocol = 'jdbc'; subprotocol = 'sqlite'; resource = dbpath;
    url = strjoin({protocol, subprotocol, resource},':');
    
    %Open Connection
    SQLite_Database = database(dbpath, user, password, driver, url);
    
    %Check that the connection was successful
    assert(isa(SQLite_Database.Handle,'org.sqlite.SQLiteConnection'),...
        'Unable to Connect to Database. Check your network connection');
    
    %% Turn on Foriegn Key Support
    % Get a handle to the underlying JDBC connection
    s = SQLite_Database.Handle.createStatement;
    
    % Use this statement to execute the query
    s.execute('PRAGMA foreign_keys=ON');
    % Close the statement
    s.close;
end
