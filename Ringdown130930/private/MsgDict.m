% This is the error/warning flag class
classdef MsgDict < handle
    
    properties
        type = {};
        num_key = [];
        err_msg = {};
    end
    
    methods
        function this = MsgDict(type, key, msg),
            if nargin == 0,
                this = this;
            elseif nargin == 3,
                this.type = type;
                this.num_key = key;
                this.err_msg = msg;
            end
        end
        
        function add_elem(this, type, key, msg),
            this.type = [this.type; type];
            this.num_key = [this.num_key; key];
            this.err_msg = [this.err_msg; msg];
        end
        
        function item_key = get_key(this, key),
            if nargin == 1,
                fprintf('An error code is required to make a decision!\n');
            else,
                item_key = this.num_key(find(this.num_key == key));
            end
        end
        
        function print_msg(this, key),
            if nargin == 1,
                fprintf('Really? Give me a code error if you want something!\n');
            else,
                msg = [this.type{find(this.num_key == key)}, ': ', this.err_msg{find(this.num_key == key)}];
                fprintf(2, '%s\n', msg);
            end
        end
    end
    
end