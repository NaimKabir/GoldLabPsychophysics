classdef testOom2cppSubclass < testOom2cppClass & someOtherClass
    
    properties
        prop3;
    end
    
    events
        EventThree;
    end
    
    methods
        function self = testOom2cppSubclass
            self. self@testOom2cppClass;
        end
    end
end