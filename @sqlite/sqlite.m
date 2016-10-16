classdef sqlite
    %Class for connecting to an sqlite database
    
    properties
        conn = [];
    end
    
    methods
        function obj = sqlite(dbpath)
            import py.sqlite3.*
            
            obj.conn = py.sqlite3.connect(dbpath);
        end
        
        function execute(obj, SQLQuery)
            obj.conn.execute(SQLQuery);
        end
        
        function record = fetch(obj, SQLQuery)
            %Run and fetch the query
            cur = obj.conn.execute(SQLQuery);
            results = cur.fetchall();
            
            %Convert py.list to cell
            results = cell(results);
            record = cell(length(results),length(results{1}));
            for i = 1:length(results)
                record(i,:) = cell(results{i});
            end
            
            %Convert python datatypes to matlab
            record = cellfun(@py2Mat,record, 'UniformOutput',0);
        end        
    end
end

function matData = py2Mat(pyData)
    switch true
        case isa(pyData, 'py.str')
            %Convert py.str to char
            matData = char(pyData);
        case isa(pyData, 'py.int')
            %Convert py.int to double
            matData = double(pyData);
    end
    
end